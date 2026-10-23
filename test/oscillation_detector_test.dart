import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_moi_cp/logic/oscillation_detector.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('OscillationDetector achieves sub-millisecond period accuracy via sub-sample interpolation', () async {
    OscillationResult? result;

    final detector = OscillationDetector(
      onStateChanged: (state) {},
      onMeasurementComplete: (res) {
        result = res;
      },
      onProgressUpdate: (progress) {},
    );

    detector.setRequiredCycles(5);
    detector.setSkipFirstCycles(0);

    // Simulate phone in 45-degree orientation (READY)
    final accelDt = DateTime.fromMicrosecondsSinceEpoch(0);
    detector.handleAccelerometer(AccelerometerEvent(6.93, 6.93, 0.0, accelDt));
    expect(detector.currentState, equals(OscillationState.READY));

    // Arm detector
    detector.arm();
    expect(detector.currentState, equals(OscillationState.ARMED));

    // True period: 0.5234 seconds (not a multiple of 10ms sampling interval)
    const double truePeriodSec = 0.5234;
    const int dtMicroseconds = 10000; // 10ms = 10,000us

    int currentMicroseconds = 0;

    // Simulate nudge to transition ARMED -> SETTLING -> ACTIVE_COUNTING
    for (int step = 0; step < 2000; step++) {
      currentMicroseconds += dtMicroseconds;
      final dt = DateTime.fromMicrosecondsSinceEpoch(currentMicroseconds);

      final double tSec = currentMicroseconds / 1000000.0;
      // Sinusoidal rotation around 45 deg angle
      final double omega = 2 * pi / truePeriodSec;
      final double gyroVal = 1.5 * sin(omega * tSec);

      await detector.handleGyroscope(GyroscopeEvent(gyroVal * 0.7071, gyroVal * 0.7071, 0.0, dt));

      if (result != null) break;
    }

    expect(result, isNotNull);
    final calculatedPeriod = result!.averagePeriod;

    // Without sub-sample interpolation, 100 Hz sampling would quantize cycles to 0.520s or 0.530s (error ~0.0034s - 0.0066s).
    // With sub-sample interpolation, accuracy is well within 0.0005 seconds (< 0.5 ms).
    expect((calculatedPeriod - truePeriodSec).abs(), lessThan(0.0005));
  });

  test('OscillationDetector exhibits zero drift across 10 consecutive high MOI measurement runs', () async {
    const double trueHighMoiPeriodSec = 1.0825; // Long period high MOI object
    const int dtMicroseconds = 10000; // 100 Hz sampling (10ms)
    final List<double> calculatedPeriods = [];

    final detector = OscillationDetector(
      onStateChanged: (state) {},
      onMeasurementComplete: (res) {
        calculatedPeriods.add(res.averagePeriod);
      },
      onProgressUpdate: (progress) {},
    );

    detector.setRequiredCycles(5);
    detector.setSkipFirstCycles(0);

    int currentMicroseconds = 0;

    for (int run = 0; run < 10; run++) {
      // 1. Orient device to READY
      final accelDt = DateTime.fromMicrosecondsSinceEpoch(currentMicroseconds);
      detector.handleAccelerometer(AccelerometerEvent(6.93, 6.93, 0.0, accelDt));

      // 2. Settle motionless in READY state to let baseline track
      for (int i = 0; i < 20; i++) {
        currentMicroseconds += dtMicroseconds;
        final dt = DateTime.fromMicrosecondsSinceEpoch(currentMicroseconds);
        await detector.handleGyroscope(GyroscopeEvent(0.0, 0.0, 0.0, dt));
      }

      // 3. Arm detector
      detector.arm();

      // 4. Simulate oscillation run with nudge
      final double runStartSec = currentMicroseconds / 1000000.0;
      final double omega = 2 * pi / trueHighMoiPeriodSec;

      for (int step = 0; step < 2000; step++) {
        currentMicroseconds += dtMicroseconds;
        final dt = DateTime.fromMicrosecondsSinceEpoch(currentMicroseconds);

        final double tRel = (currentMicroseconds / 1000000.0) - runStartSec;
        // Damped sine wave
        final double gyroVal = 1.8 * exp(-0.04 * tRel) * sin(omega * tRel);

        await detector.handleGyroscope(GyroscopeEvent(gyroVal * 0.7071, gyroVal * 0.7071, 0.0, dt));

        if (calculatedPeriods.length == run + 1) break;
      }
    }

    expect(calculatedPeriods.length, equals(10));

    // Verify max drift across all 10 runs is strictly less than 0.0001 seconds (0.1 ms)
    final double minPeriod = calculatedPeriods.reduce(min);
    final double maxPeriod = calculatedPeriods.reduce(max);
    final double driftRange = maxPeriod - minPeriod;

    expect(driftRange, lessThan(0.0001));
    for (final p in calculatedPeriods) {
      expect((p - trueHighMoiPeriodSec).abs(), lessThan(0.0005));
    }
  });
}
