import 'dart:math';

class CalibrationResult {
  final double springConstant;
  final double deviceInertia;

  CalibrationResult({
    required this.springConstant,
    required this.deviceInertia,
  });
}

class MomentOfInertiaCalculator {
  static const double kappaConversion = 980.665;

  /// Calculates the MOI of an object given period and device constants.
  static double calculateObjectMOI(
    double period,
    double springConstant,
    double deviceInertia,
  ) {
    if (period <= 0 || springConstant <= 0) return 0.0;
    final totalInertia = (springConstant * pow(period, 2)) / (4 * pow(pi, 2));
    final moi = totalInertia - deviceInertia;
    return moi < 0 ? 0.0 : moi;
  }

  /// Calibrates using two known objects.
  static CalibrationResult calibrateWithTwoObjects(
    double periodA,
    double inertiaA,
    double periodB,
    double inertiaB,
  ) {
    if (periodA <= 0 || periodB <= 0 || periodA == periodB || inertiaA == inertiaB) {
      return CalibrationResult(springConstant: 0.0, deviceInertia: 0.0);
    }

    // kappa = (4 * PI^2 * (I_A - I_B)) / (T_A^2 - T_B^2)
    final kappa = (4 * pow(pi, 2) * (inertiaA - inertiaB)) / (pow(periodA, 2) - pow(periodB, 2));

    // deviceInertia = (kappa * T_A^2) / (4 * PI^2) - I_A
    final deviceInertia = (kappa * pow(periodA, 2)) / (4 * pow(pi, 2)) - inertiaA;

    return CalibrationResult(
      springConstant: kappa.abs(),
      deviceInertia: deviceInertia,
    );
  }
}
