import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_moi_cp/logic/curve_fitter.dart';

void main() {
  group('CurveFitter Rule 1: Data Windowing & Integer Cycle Truncation', () {
    test('Truncates dataset to [tStart, tEnd] boundaries when >= 10 points remain', () {
      // 100 points spaced by 0.01s (0.0s to 0.99s)
      final rawPoints = List.generate(
        100,
        (i) => Point<double>(i * 0.01, sin(2 * pi * i * 0.01)),
      );

      // Integer cycle window [0.2, 0.8] -> 61 points
      final fitter = CurveFitter(
        rawPoints,
        tStart: 0.2,
        tEnd: 0.8,
        initialPeriodHint: 1.0,
      );

      final period = fitter.optimizePeriod();
      expect(period, isNotNull);
    });

    test('Falls back to un-truncated dataset if truncated window has fewer than 10 points', () {
      // 30 points from 0.0s to 0.29s
      final rawPoints = List.generate(
        30,
        (i) => Point<double>(i * 0.01, 1.5 * sin(2 * pi * 2.0 * i * 0.01)),
      );

      // Window [0.10, 0.13] contains only 4 points (< 10)
      final fitter = CurveFitter(
        rawPoints,
        tStart: 0.10,
        tEnd: 0.13,
        initialPeriodHint: 0.5,
      );

      // Optimization should succeed using fallback to all 30 points
      final period = fitter.optimizePeriod();
      expect(period, isNotNull);
      expect((period! - 0.5).abs(), lessThan(0.05));
    });
  });

  group('CurveFitter Rule 2: Initial Parameter Seeds Calculation', () {
    test('Computes seeds A, d, w, phi, C accurately according to rules', () {
      const double trueA = 2.0;
      const double trueD = 0.05;
      const double trueW = 2 * pi * 2.0; // 2 Hz -> period 0.5s
      const double trueC = 0.5;

      final points = List.generate(100, (i) {
        final t = i * 0.005;
        final y = trueA * exp(-trueD * t) * sin(trueW * t) + trueC;
        return Point<double>(t, y);
      });

      final seeds = CurveFitter.computeInitialSeeds(
        points,
        duration: 0.495,
        initialPeriodHint: 0.5,
      );

      final seedA = seeds[0];
      final seedD = seeds[1];
      final seedW = seeds[2];
      final seedC = seeds[4];

      expect(seedA, greaterThan(0.01));
      expect(seedD, equals(0.05));
      expect(seedW, closeTo(2 * pi / 0.5, 1e-4));
      expect(seedC, closeTo(trueC, 0.5));
    });
  });

  group('CurveFitter Rule 3: Levenberg-Marquardt Optimization Target', () {
    test('Optimizes damped sinusoid signal to extract precise period T = 2*pi/w', () {
      const double truePeriod = 0.6543;
      const double trueW = 2 * pi / truePeriod;
      const double trueA = 1.8;
      const double trueD = 0.04;
      const double trueC = 0.1;

      // Generate 200 noisy/damped points at 100 Hz
      final points = List.generate(200, (i) {
        final t = i * 0.01;
        final y = trueA * exp(-trueD * t) * sin(trueW * t + 0.2) + trueC;
        return Point<double>(t, y);
      });

      final fitter = CurveFitter(points, initialPeriodHint: 0.65);
      final optimizedPeriod = fitter.optimizePeriod();

      expect(optimizedPeriod, isNotNull);
      expect((optimizedPeriod! - truePeriod).abs(), lessThan(0.001));
    });
  });
}
