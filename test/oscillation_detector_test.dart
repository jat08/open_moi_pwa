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

      detector.handleGyroscope(GyroscopeEvent(gyroVal * 0.7071, gyroVal * 0.7071, 0.0, dt));

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
        detector.handleGyroscope(GyroscopeEvent(0.0, 0.0, 0.0, dt));
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

        detector.handleGyroscope(GyroscopeEvent(gyroVal * 0.7071, gyroVal * 0.7071, 0.0, dt));

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

  group('Gyroscope DC Bias Thermal Drift Tracking System', () {
    test('Rule 1 & 3: Updates baseline using 95/5 EMA filter when strictly stationary (gyroMag < 0.02 rad/s) in READY state', () async {
      final detector = OscillationDetector(
        onStateChanged: (_) {},
        onMeasurementComplete: (_) {},
        onProgressUpdate: (_) {},
      );

      final dt0 = DateTime.fromMicrosecondsSinceEpoch(0);
      detector.handleAccelerometer(AccelerometerEvent(6.93, 6.93, 0.0, dt0));
      expect(detector.currentState, equals(OscillationState.READY));
      expect(detector.gyroBaseline, equals(0.0));

      // Small stationary rotation rate: gyroMag = sqrt(0.01^2 + 0.01^2) = ~0.01414 rad/s (< 0.02 rad/s)
      final dt1 = DateTime.fromMicrosecondsSinceEpoch(10000);
      final gyroEvent = GyroscopeEvent(0.01, 0.01, 0.0, dt1);
      detector.handleGyroscope(gyroEvent);

      // Expected vRot: (0.01*6.93 + 0.01*6.93) / 9.80 = ~0.014143
      // Expected new_baseline = 0.95 * 0.0 + 0.05 * vRot
      final gMag = sqrt(6.93 * 6.93 + 6.93 * 6.93);
      final expectedVRot = (0.01 * 6.93 + 0.01 * 6.93) / gMag;
      final expectedBaseline1 = 0.05 * expectedVRot;

      expect(detector.gyroBaseline, closeTo(expectedBaseline1, 1e-6));

      // Second stationary reading
      final dt2 = DateTime.fromMicrosecondsSinceEpoch(20000);
      detector.handleGyroscope(gyroEvent);

      final expectedBaseline2 = 0.95 * expectedBaseline1 + 0.05 * expectedVRot;
      expect(detector.gyroBaseline, closeTo(expectedBaseline2, 1e-6));
    });

    test('Rule 1: Does NOT update baseline when angular velocity magnitude >= 0.02 rad/s in READY state', () async {
      final detector = OscillationDetector(
        onStateChanged: (_) {},
        onMeasurementComplete: (_) {},
        onProgressUpdate: (_) {},
      );

      final dt0 = DateTime.fromMicrosecondsSinceEpoch(0);
      detector.handleAccelerometer(AccelerometerEvent(6.93, 6.93, 0.0, dt0));
      expect(detector.currentState, equals(OscillationState.READY));

      // Motion exceeding stationary threshold: gyroMag = sqrt(0.05^2 + 0.05^2) = ~0.0707 rad/s (>= 0.02 rad/s)
      final dt1 = DateTime.fromMicrosecondsSinceEpoch(10000);
      detector.handleGyroscope(GyroscopeEvent(0.05, 0.05, 0.0, dt1));

      // Baseline must remain 0.0
      expect(detector.gyroBaseline, equals(0.0));
    });

    test('Rule 2: Baseline freezes as soon as system transitions to ARMED or active measurement states', () async {
      final detector = OscillationDetector(
        onStateChanged: (_) {},
        onMeasurementComplete: (_) {},
        onProgressUpdate: (_) {},
      );

      final dt0 = DateTime.fromMicrosecondsSinceEpoch(0);
      detector.handleAccelerometer(AccelerometerEvent(6.93, 6.93, 0.0, dt0));
      expect(detector.currentState, equals(OscillationState.READY));

      // Establish baseline while stationary in READY state
      final dt1 = DateTime.fromMicrosecondsSinceEpoch(10000);
      detector.handleGyroscope(GyroscopeEvent(0.01, 0.01, 0.0, dt1));
      final frozenBaseline = detector.gyroBaseline;
      expect(frozenBaseline, greaterThan(0.0));

      // Transition to ARMED state
      detector.arm();
      expect(detector.currentState, equals(OscillationState.ARMED));

      // Send stationary gyro readings while in ARMED state
      final dt2 = DateTime.fromMicrosecondsSinceEpoch(20000);
      detector.handleGyroscope(GyroscopeEvent(0.01, 0.01, 0.0, dt2));

      // Verify baseline remains strictly frozen
      expect(detector.gyroBaseline, equals(frozenBaseline));

      // Trigger nudge to transition ARMED -> SETTLING
      final dt3 = DateTime.fromMicrosecondsSinceEpoch(30000);
      detector.handleGyroscope(GyroscopeEvent(0.5, 0.5, 0.0, dt3));
      expect(detector.currentState, equals(OscillationState.SETTLING));

      // Send stationary gyro readings during SETTLING
      final dt4 = DateTime.fromMicrosecondsSinceEpoch(40000);
      detector.handleGyroscope(GyroscopeEvent(0.01, 0.01, 0.0, dt4));

      // Verify baseline is still frozen
      expect(detector.gyroBaseline, equals(frozenBaseline));
    });
  });
}
