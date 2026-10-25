import 'dart:math';

/// A pure-Dart implementation of the Levenberg-Marquardt non-linear least squares algorithm
/// to fit raw gyroscope data to a damped sine wave formula:
/// y(t) = A * exp(-d*t) * sin(w*t + phi) + C
class CurveFitter {
  final List<Point<double>> dataPoints; // x: time in seconds, y: gyro value
  final double? initialPeriodHint; // Optional zero-crossing period estimate
  final double? tStart; // Exact integer cycle start timestamp
  final double? tEnd; // Exact integer cycle end timestamp

  CurveFitter(
    this.dataPoints, {
    this.initialPeriodHint,
    this.tStart,
    this.tEnd,
  });

  /// Analyzes the dataset using Levenberg-Marquardt non-linear curve fitting
  /// and returns the analytically optimized period (in seconds), or null if fitting fails.
  double? optimizePeriod() {
    if (dataPoints.isEmpty) return null;

    // Rule 1: Truncate raw time-series gyro data to exact integer cycle boundaries [tStart, tEnd]
    List<Point<double>> targetPoints = dataPoints;
    if (tStart != null && tEnd != null && tEnd! > tStart!) {
      final truncated = dataPoints
          .where((p) => p.x >= tStart! && p.x <= tEnd!)
          .toList();
      // Fall back to the un-truncated raw dataset if fewer than 10 points remain
      if (truncated.length >= 10) {
        targetPoints = truncated;
      }
    }

    if (targetPoints.length < 10) return null;

    // Time normalization so t'_0 = 0.0 for numerical stability
    final double startTime = targetPoints.first.x;
    final double endTime = targetPoints.last.x;
    final double duration = endTime - startTime;
    if (duration <= 0) return null;

    final List<Point<double>> normPoints = targetPoints
        .map((p) => Point<double>(p.x - startTime, p.y))
        .toList();

    // Rule 2: Compute Initial Parameter Seeds [A, d, w, phi, C]
    List<double> params = computeInitialSeeds(
      normPoints,
      duration: duration,
      initialPeriodHint: initialPeriodHint,
    );

    List<double> bestParams = List.from(params);

    // Rule 3: Levenberg-Marquardt Optimization
    double lambda = 1e-3; // Initial Marquardt damping parameter
    int maxIterations = 100;
    double tolerance = 1e-8;

    double currentSse = _calculateSse(normPoints, params);
    double bestSse = currentSse;

    for (int iter = 0; iter < maxIterations; iter++) {
      // Build Jacobian (J) and Residuals (R)
      List<List<double>> J = List.generate(normPoints.length, (_) => List.filled(5, 0.0));
      List<double> R = List.filled(normPoints.length, 0.0);

      for (int i = 0; i < normPoints.length; i++) {
        double t = normPoints[i].x;
        double y = normPoints[i].y;

        double pA = params[0];
        double pd = params[1];
        double pw = params[2];
        double pphi = params[3];
        double pC = params[4];

        double expPart = exp(-pd * t);
        double angle = pw * t + pphi;
        double sinPart = sin(angle);
        double cosPart = cos(angle);

        double yModel = pA * expPart * sinPart + pC;
        R[i] = y - yModel;

        // Partial Derivatives
        J[i][0] = expPart * sinPart; // d/dA
        J[i][1] = -pA * t * expPart * sinPart; // d/dd
        J[i][2] = pA * t * expPart * cosPart; // d/dw
        J[i][3] = pA * expPart * cosPart; // d/dphi
        J[i][4] = 1.0; // d/dC
      }

      // Compute J^T * J (5x5) and J^T * R (5x1)
      List<List<double>> JtJ = List.generate(5, (_) => List.filled(5, 0.0));
      List<double> JtR = List.filled(5, 0.0);

      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          double sum = 0.0;
          for (int k = 0; k < normPoints.length; k++) {
            sum += J[k][i] * J[k][j];
          }
          JtJ[i][j] = sum;
        }

        double sumR = 0.0;
        for (int k = 0; k < normPoints.length; k++) {
          sumR += J[k][i] * R[k];
        }
        JtR[i] = sumR;
      }

      // Apply Levenberg-Marquardt diagonal damping: JtJ[i][i] * (1 + lambda)
      List<List<double>> JtJ_damped = List.generate(5, (i) => List.from(JtJ[i]));
      for (int i = 0; i < 5; i++) {
        double diag = JtJ[i][i];
        JtJ_damped[i][i] = diag * (1.0 + lambda) + (diag == 0.0 ? lambda : 0.0);
      }

      // Solve damped system for parameter step delta
      List<double>? delta = _solveGaussian(JtJ_damped, JtR);
      if (delta == null) {
        lambda *= 10.0; // Increase damping on singular matrix step
        if (lambda > 1e12) break;
        continue;
      }

      // Evaluate candidate parameters
      List<double> candidateParams = List.generate(5, (i) => params[i] + delta[i]);
      double candidateSse = _calculateSse(normPoints, candidateParams);

      if (candidateSse < currentSse) {
        // Accept LM step
        double sseDiff = currentSse - candidateSse;
        params = candidateParams;
        currentSse = candidateSse;

        if (candidateSse < bestSse) {
          bestSse = candidateSse;
          bestParams = List.from(candidateParams);
        }

        lambda = max(1e-7, lambda / 10.0); // Shift towards Gauss-Newton speed

        if (sseDiff / max(1e-6, currentSse) < tolerance) {
          break; // Convergence reached
        }
      } else {
        // Reject LM step and increase damping
        lambda *= 10.0;
        if (lambda > 1e12) break;
      }
    }

    // Final optimized frequency from best parameters
    double finalW = bestParams[2].abs();
    if (finalW <= 0.1 || finalW > 200.0) return null;

    return (2 * pi) / finalW;
  }

  /// Rule 2 Initial Parameter Seeds Calculation [A, d, w, phi, C]
  static List<double> computeInitialSeeds(
    List<Point<double>> normPoints, {
    required double duration,
    double? initialPeriodHint,
  }) {
    double yMax = -double.infinity;
    double yMin = double.infinity;
    double ySum = 0.0;

    int zeroCrossings = 0;
    bool wasPositive = normPoints.first.y > 0;

    for (var p in normPoints) {
      if (p.y > yMax) yMax = p.y;
      if (p.y < yMin) yMin = p.y;
      ySum += p.y;

      bool isPositive = p.y > 0;
      if (isPositive != wasPositive) {
        zeroCrossings++;
        wasPositive = isPositive;
      }
    }

    // C: Mean / baseline offset
    double C = ySum / normPoints.length;

    // A: Amplitude = max(0.01, (yMax - yMin) / 2.0)
    double A = max(0.01, (yMax - yMin) / 2.0);

    // d: Damping factor seeded at 0.05
    double d = 0.05;

    // w: Angular frequency seed
    double w;
    if (initialPeriodHint != null && initialPeriodHint > 0) {
      w = (2 * pi) / initialPeriodHint;
    } else {
      double cycles = zeroCrossings / 2.0;
      if (cycles < 0.25) cycles = 1.0;
      w = (cycles / max(1e-6, duration)) * 2 * pi;
    }

    // phi: Phase shift estimated from first normalized point y0 relative to C
    double y0 = normPoints.first.y;
    double ratio = ((y0 - C) / A).clamp(-1.0, 1.0);
    double phi = asin(ratio);
    if (normPoints.length > 1 && normPoints[1].y < normPoints[0].y) {
      phi = pi - phi;
    }

    return [A, d, w, phi, C];
  }

  double _calculateSse(List<Point<double>> pts, List<double> p) {
    double sse = 0.0;
    double pA = p[0];
    double pd = p[1];
    double pw = p[2];
    double pphi = p[3];
    double pC = p[4];

    for (var pt in pts) {
      double t = pt.x;
      double yModel = pA * exp(-pd * t) * sin(pw * t + pphi) + pC;
      double r = pt.y - yModel;
      sse += r * r;
    }
    return sse;
  }

  /// Gaussian Elimination to solve matrix equation Ax = b
  List<double>? _solveGaussian(List<List<double>> A, List<double> b) {
    int n = b.length;
    List<List<double>> matrix = List.generate(n, (i) => List.from(A[i])..add(b[i]));

    for (int i = 0; i < n; i++) {
      // Pivot search
      double maxEl = matrix[i][i].abs();
      int maxRow = i;
      for (int k = i + 1; k < n; k++) {
        if (matrix[k][i].abs() > maxEl) {
          maxEl = matrix[k][i].abs();
          maxRow = k;
        }
      }

      if (maxEl < 1e-12) return null; // Singular matrix

      // Swap max row to current row
      List<double> tmp = matrix[maxRow];
      matrix[maxRow] = matrix[i];
      matrix[i] = tmp;

      // Eliminate column entries below pivot
      for (int k = i + 1; k < n; k++) {
        double c = -matrix[k][i] / matrix[i][i];
        for (int j = i; j < n + 1; j++) {
          if (i == j) {
            matrix[k][j] = 0.0;
          } else {
            matrix[k][j] += c * matrix[i][j];
          }
        }
      }
    }

    // Back substitution
    List<double> x = List.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      x[i] = matrix[i][n] / matrix[i][i];
      for (int k = i - 1; k >= 0; k--) {
        matrix[k][n] -= matrix[k][i] * x[i];
      }
    }

    return x;
  }
}
