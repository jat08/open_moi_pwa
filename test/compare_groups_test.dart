import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Unit Conversions for Group Comparison', () {
    double convertMass(double val, String fromUnit, String toUnit) {
      if (val <= 0) return 0.0;
      double oz;
      switch (fromUnit.toLowerCase()) {
        case 'g':
          oz = val / 28.349523125;
          break;
        case 'lb':
          oz = val * 16.0;
          break;
        case 'kg':
          oz = val * 35.27396195;
          break;
        case 'oz':
        default:
          oz = val;
      }
      switch (toUnit.toLowerCase()) {
        case 'g':
          return oz * 28.349523125;
        case 'lb':
          return oz / 16.0;
        case 'kg':
          return oz / 35.27396195;
        case 'oz':
        default:
          return oz;
      }
    }

    double convertDistance(double val, String fromUnit, String toUnit) {
      if (val <= 0) return 0.0;
      double inches = fromUnit.toLowerCase() == 'cm' ? val / 2.54 : val;
      return toUnit.toLowerCase() == 'cm' ? inches * 2.54 : inches;
    }

    test('Mass conversions correctly convert between oz, g, lb, kg', () {
      expect(convertMass(1.0, 'oz', 'g'), closeTo(28.3495, 0.001));
      expect(convertMass(16.0, 'oz', 'lb'), closeTo(1.0, 0.001));
      expect(convertMass(1000.0, 'g', 'kg'), closeTo(1.0, 0.001));
      expect(convertMass(1.0, 'lb', 'oz'), closeTo(16.0, 0.001));
    });

    test('Distance conversions correctly convert between inches and cm', () {
      expect(convertDistance(10.0, 'in', 'cm'), closeTo(25.4, 0.001));
      expect(convertDistance(25.4, 'cm', 'in'), closeTo(10.0, 0.001));
    });
  });
}
