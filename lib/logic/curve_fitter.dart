import 'dart:math';

/// A pure-Dart implementation of a Gauss-Newton non-linear least squares optimizer
/// to fit raw gyroscope data to a damped sine wave formula:
/// y(t) = A * exp(-d*t) * sin(w*t + phi) + C
class CurveFitter {
  final List<Point<double>> dataPoints; // x: time in seconds, y: gyro value

  CurveFitter(this.dataPoints);

  /// Analyzes the dataset and returns the optimized period (in seconds)
  double? optimizePeriod() {
    if (dataPoints.length < 10) return null;

    // 1. Initial Guesses
    double tMin = dataPoints.first.x;
    double tMax = dataPoints.last.x;
    double duration = tMax - tMin;

    double yMax = -double.infinity;
    double yMin = double.infinity;
    double ySum = 0;

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

    double C = ySum / dataPoints.length; // DC Bias
    double A = (yMax - yMin) / 2.0;      // Amplitude
    double d = 0.05;                     // Damping factor guess

    // Estimate frequency based on zero crossings (2 crossings = 1 full cycle)
    double cycles = zeroCrossings / 2.0;
    double w = (cycles / duration) * 2 * pi;

    double phi = 0.0; // Phase shift guess

    // Parameters vector: [A, d, w, phi, C]
    List<double> params = [A, d, w, phi, C];

    // Gauss-Newton Iterations
    int maxIterations = 20;
    double tolerance = 1e-6;
    double lastRmse = double.infinity;

    for (int iter = 0; iter < maxIterations; iter++) {
      // Create Jacobian (J) and Residuals (R)
      List<List<double>> J = List.generate(dataPoints.length, (_) => List.filled(5, 0.0));
      List<double> R = List.filled(dataPoints.length, 0.0);

      double sse = 0.0;

      for (int i = 0; i < dataPoints.length; i++) {
        double t = dataPoints[i].x;
        double y = dataPoints[i].y;

        double pA = params[0];
        double pd = params[1];
        double pw = params[2];
        double pphi = params[3];
        double pC = params[4];

        double expPart = exp(-pd * t);
        double sinPart = sin(pw * t + pphi);
        double cosPart = cos(pw * t + pphi);

        // Theoretical y value
        double yModel = pA * expPart * sinPart + pC;

        // Residual
        double residual = y - yModel;
        R[i] = residual;
        sse += residual * residual;

        // Partial derivatives for Jacobian matrix
        J[i][0] = expPart * sinPart;                               // d/dA
        J[i][1] = -pA * t * expPart * sinPart;                     // d/dd
        J[i][2] = pA * t * expPart * cosPart;                      // d/dw
        J[i][3] = pA * expPart * cosPart;                          // d/dphi
        J[i][4] = 1.0;                                             // d/dC
      }

      double rmse = sqrt(sse / dataPoints.length);
      if ((lastRmse - rmse).abs() < tolerance) {
        break; // Converged
      }
      lastRmse = rmse;

      // J^T * J
      List<List<double>> JtJ = List.generate(5, (_) => List.filled(5, 0.0));
      for (int i = 0; i < 5; i++) {
        for (int j = 0; j < 5; j++) {
          double sum = 0;
          for (int k = 0; k < dataPoints.length; k++) {
            sum += J[k][i] * J[k][j];
          }
          JtJ[i][j] = sum;
        }
      }

      // J^T * R
      List<double> JtR = List.filled(5, 0.0);
      for (int i = 0; i < 5; i++) {
        double sum = 0;
        for (int k = 0; k < dataPoints.length; k++) {
          sum += J[k][i] * R[k];
        }
        JtR[i] = sum;
      }

      // Solve (J^T * J) * delta = J^T * R using Gaussian Elimination
      List<double>? delta = _solveGaussian(JtJ, JtR);
      if (delta == null) {
        // Singular matrix, optimization failed to invert
        return null;
      }

      // Update parameters
      for (int i = 0; i < 5; i++) {
        params[i] += delta[i];
      }
    }

    // Final optimized frequency
    double finalW = params[2];
    if (finalW <= 0) return null;

    // Period = 2 * pi / w
    return (2 * pi) / finalW.abs();
  }

  /// Basic Gaussian Elimination to solve Ax = b
  List<double>? _solveGaussian(List<List<double>> A, List<double> b) {
    int n = b.length;
    List<List<double>> matrix = List.generate(n, (i) => List.from(A[i])..add(b[i]));

    for (int i = 0; i < n; i++) {
      // Pivot
      double maxEl = matrix[i][i].abs();
      int maxRow = i;
      for (int k = i + 1; k < n; k++) {
        if (matrix[k][i].abs() > maxEl) {
          maxEl = matrix[k][i].abs();
          maxRow = k;
        }
      }

      if (maxEl < 1e-12) return null; // Singular

      // Swap
      List<double> tmp = matrix[maxRow];
      matrix[maxRow] = matrix[i];
      matrix[i] = tmp;

      // Eliminate
      for (int k = i + 1; k < n; k++) {
        double c = -matrix[k][i] / matrix[i][i];
        for (int j = i; j < n + 1; j++) {
          if (i == j) {
            matrix[k][j] = 0;
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