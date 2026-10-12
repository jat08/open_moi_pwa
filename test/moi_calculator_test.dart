import 'package:flutter_test/flutter_test.dart';
import 'package:open_moi_cp/logic/moi_calculator.dart';

void main() {
  group('MomentOfInertiaCalculator Tests', () {
    test('calculateObjectMOI returns correct physical inertia', () {
      // Period T = 0.5s, spring constant kappa = 1000.0, deviceInertia = 2.0
      // Total Inertia = (1000 * 0.25) / (4 * pi^2) = 250 / 39.478417604 = 6.33257
      // MOI = 6.33257 - 2.0 = 4.33257
      final moi = MomentOfInertiaCalculator.calculateObjectMOI(0.5, 1000.0, 2.0);
      expect(moi, closeTo(4.33257, 0.001));
    });

    test('calculateObjectMOI handles invalid zero or negative inputs', () {
      expect(MomentOfInertiaCalculator.calculateObjectMOI(0.0, 1000.0, 2.0), 0.0);
      expect(MomentOfInertiaCalculator.calculateObjectMOI(0.5, 0.0, 2.0), 0.0);
    });

    test('calibrateWithTwoObjects returns correct spring constant and device inertia', () {
      const inertiaA = 13.2135;
      const inertiaB = 177.1500;
      const periodA = 0.6947;
      const periodB = 0.2607;

      final result = MomentOfInertiaCalculator.calibrateWithTwoObjects(
        periodA,
        inertiaA,
        periodB,
        inertiaB,
      );

      expect(result.springConstant, greaterThan(0));
      expect(result.deviceInertia, isNotNull);
    });
  });
}
