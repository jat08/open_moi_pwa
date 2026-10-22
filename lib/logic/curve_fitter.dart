import 'dart:math';

/// A pure-Dart implementation of the Levenberg-Marquardt non-linear least squares algorithm
/// to fit raw gyroscope data to a damped sine wave formula:
/// y(t) = A * exp(-d*t) * sin(w*t + phi) + C
class CurveFitter {
  final List<Point<double>> dataPoints; // x: time in seconds, y: gyro value

  CurveFitter(this.dataPoints);

  /// Analyzes the dataset using Levenberg-Marquardt non-linear curve fitting
  /// and returns the analytically optimized period (in seconds), or null if fitting fails.
  double? optimizePeriod() {
    if (dataPoints.length < 10) return null;

    // 1. Initial Data Analysis & Seed Generation
    double tMin = dataPoints.first.x;
    double tMax = dataPoints.last.x;
    double duration = tMax - tMin;
    if (duration <= 0) return null;

    double yMax = -double.infinity;
    double yMin = double.infinity;
    double ySum = 0.0;

    int zeroCrossings = 0;
    bool wasPositive = dataPoints.first.y > 0;

    for (var p in dataPoints) {
      if (p.y > yMax) yMax = p.y;
      if (p.y < yMin) yMin = p.y;
      ySum += p.y;

      bool isPositive = p.y > 0;
      if (isPositive != wasPositive) {
        zeroCrossings++;
        wasPositive = isPositive;
      }
    }

    double C = ySum / dataPoints.length;          // Initial DC Bias seed
    double A = max(0.01, (yMax - yMin) / 2.0);   // Initial Amplitude seed
    double d = 0.05;                              // Initial Damping factor seed

    double cycles = zeroCrossings / 2.0;
    if (cycles < 0.5) return null;
    double w = (cycles / duration) * 2 * pi;      // Initial Angular Frequency seed
    double phi = 0.0;                             // Initial Phase shift seed

    // Parameters vector: [A, d, w, phi, C]
    List<double> params = [A, d, w, phi, C];

    // 2. Levenberg-Marquardt Parameters
    double lambda = 1e-3; // Initial Marquardt damping parameter
    int maxIterations = 100;
    double tolerance = 1e-10;

    double currentSse = _calculateSse(params);

    for (int iter = 0; iter < maxIterations; iter++) {
      // Build Jacobian (J) and Residuals (R)
      List<List<double>> J = List.generate(dataPoints.length, (_) => List.filled(5, 0.0));
      List<double> R = List.filled(dataPoints.length, 0.0);

      for (int i = 0; i < dataPoints.length; i++) {
        double t = dataPoints[i].x;
        double y = dataPoints[i].y;

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
        J[i][0] = expPart * sinPart;                      // d/dA
        J[i][1] = -pA * t * expPart * sinPart;            // d/dd
        J[i][2] = pA * t * expPart * cosPart;             // d/dw
        J[i][3] = pA * expPart * cosPart;                 // d/dphi
        J[i][4] = 1.0;                                    // d/dC
      }

      // Compute J^T * J (5x5) and J^T * R (5x1)
      List<List<double>> JtJ = List.generate(5, (_) => List.filled(5, 0.0));
      List<double> JtR = List.filled(5, 0.0);

      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          double sum = 0.0;
          for (int k = 0; k < dataPoints.length; k++) {
            sum += J[k][i] * J[k][j];
          }
          JtJ[i][j] = sum;
        }

        double sumR = 0.0;
        for (int k = 0; k < dataPoints.length; k++) {
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
        if (lambda > 1e9) return null;
        continue;
      }

      // Evaluate candidate parameters
      List<double> candidateParams = List.generate(5, (i) => params[i] + delta[i]);
      double candidateSse = _calculateSse(candidateParams);

      if (candidateSse < currentSse) {
        // Accept LM step
        double sseDiff = currentSse - candidateSse;
        params = candidateParams;
        currentSse = candidateSse;
        lambda = max(1e-7, lambda / 10.0); // Shift towards Gauss-Newton speed

        if (sseDiff / max(1e-6, currentSse) < tolerance) {
          break; // Convergence reached
        }
      } else {
        // Reject LM step and increase damping (shift towards Gradient Descent safety)
        lambda *= 10.0;
        if (lambda > 1e9) break;
      }
    }

    // Final optimized frequency
    double finalW = params[2].abs();
    if (finalW <= 0.1 || finalW > 200.0) return null;

    return (2 * pi) / finalW;
  }

  double _calculateSse(List<double> p) {
    double sse = 0.0;
    double pA = p[0];
    double pd = p[1];
    double pw = p[2];
    double pphi = p[3];
    double pC = p[4];

    for (var pt in dataPoints) {
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
