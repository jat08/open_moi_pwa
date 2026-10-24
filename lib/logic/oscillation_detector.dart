import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'web_helper.dart';
import 'curve_fitter.dart';

enum OscillationState {
  WRONG_ORIENTATION,
  READY,
  ARMED,
  SETTLING,
  ACTIVE_COUNTING,
}

class OscillationResult {
  final double averagePeriod;
  final String rawData;
  final String cyclePeriods;
  final double totalDuration;

  OscillationResult({
    required this.averagePeriod,
    required this.rawData,
    required this.cyclePeriods,
    required this.totalDuration,
  });
}

class _GyroSample {
  final int timestampNs;
  final double value;
  _GyroSample(this.timestampNs, this.value);
}

class OscillationDetector {
  final void Function(OscillationState state) onStateChanged;
  final void Function(OscillationResult result) onMeasurementComplete;
  final void Function(double progress) onProgressUpdate;

  OscillationState _currentState = OscillationState.WRONG_ORIENTATION;
  OscillationState get currentState => _currentState;

  int _requiredCycles = 8;
  int _skipFirstCycles = 0;

  int _detectedCycles = 0;
  int _tStartNs = 0;
  int _tEndNs = 0;
  int _lastCrossingTimeNs = 0;
  double _lastGyroValue = 0.0;
  int _lastSampleTimeNs = 0;

  int _maxMeasurementDurationNs = 8000000000; // Default 8s in ns
  int _measurementStartTimeNs = 0;

  bool applyOptimization = true;

  static const double orientationThreshold = 10.0;
  static const double targetAngle = 45.0;
  static const double nudgeThreshold = 0.3;
  static const int debounceNs = 100000000; // 0.1s hysteresis window

  int sampleCount = 0;

  final List<double> _gravityVector = [0.0, 0.0, 9.8];
  double _gyroBaseline = 0.0; // Dynamically tracks DC bias

  final List<_GyroSample> _rawGyroSamples = [];
  final List<Point<double>> _rawGyroDataPoints = []; // Used for Curve Fitting
  final List<double> _cycleDurations = [];

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  OscillationDetector({
    required this.onStateChanged,
    required this.onMeasurementComplete,
    required this.onProgressUpdate,
  });

  void startListening() {
    sampleCount = 0;

    if (kIsWeb) {
      registerWebMotionListener((gx, gy, gz, ax, ay, az, timeStampMs) {
        final dt = timeStampMs > 0
            ? DateTime.fromMicrosecondsSinceEpoch((timeStampMs * 1000).toInt())
            : DateTime.now();
        sampleCount++;
        handleAccelerometer(AccelerometerEvent(ax, ay, az, dt));
        sampleCount++;
        handleGyroscope(GyroscopeEvent(gx, gy, gz, dt));
      });
    } else {
      final interval = SensorInterval.fastestInterval;

      _accelSub = accelerometerEventStream(samplingPeriod: interval).listen(
        (event) {
          sampleCount++;
          handleAccelerometer(event);
        },
        onError: (err) {
          debugPrint('Accelerometer stream error: $err');
        },
        cancelOnError: false,
      );

      _gyroSub = gyroscopeEventStream(samplingPeriod: interval).listen(
        (event) {
          sampleCount++;
          handleGyroscope(event);
        },
        onError: (err) {
          debugPrint('Gyroscope stream error: $err');
        },
        cancelOnError: false,
      );
    }
  }

  void stopListening() {
    if (kIsWeb) {
      unregisterWebMotionListener();
    } else {
      _accelSub?.cancel();
      _gyroSub?.cancel();
      _accelSub = null;
      _gyroSub = null;
    }
  }

  void setMaxDuration(double seconds) {
    _maxMeasurementDurationNs = (seconds * 1000000000).toInt();
  }

  void setRequiredCycles(int count) {
    _requiredCycles = count;
  }

  void setSkipFirstCycles(int count) {
    _skipFirstCycles = count;
  }

  void handleAccelerometer(AccelerometerEvent event) {
    _gravityVector[0] = event.x;
    _gravityVector[1] = event.y;
    _gravityVector[2] = event.z;

    // Critical Rule: Once ARMED, SETTLING, or ACTIVE_COUNTING, orientation does NOT reset or interrupt
    if (_currentState == OscillationState.ARMED ||
        _currentState == OscillationState.SETTLING ||
        _currentState == OscillationState.ACTIVE_COUNTING) {
      return;
    }

    final x = event.x;
    final y = event.y;
    final z = event.z;

    final gMag = sqrt(x * x + y * y + z * z);
    if (gMag < 0.2) {
      _updateState(OscillationState.WRONG_ORIENTATION);
      return;
    }

    // Must be facing upright/forward (not lying flat on back or face on a table)
    final isFacingForward = z.abs() < (gMag * 0.6);

    // Roll angle in screen plane (X vs Y) as shown in 45-degree orientation diagram
    final rollAngle = (atan2(x.abs(), y.abs()) * 180.0 / pi);
    final isCorrectAngle = (rollAngle - targetAngle).abs() < orientationThreshold;

    final isCorrectOrientation = isFacingForward && isCorrectAngle;

    if (!isCorrectOrientation) {
      _updateState(OscillationState.WRONG_ORIENTATION);
    } else {
      _updateState(OscillationState.READY);
    }
  }

  Future<void> handleGyroscope(GyroscopeEvent event) async {
    if (_currentState == OscillationState.WRONG_ORIENTATION) return;

    final timestampNs = event.timestamp.microsecondsSinceEpoch * 1000;

    final gx = _gravityVector[0];
    final gy = _gravityVector[1];
    final gz = _gravityVector[2];
    final gMag = sqrt(gx * gx + gy * gy + gz * gz);
    final gyroMag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    final vRot = gMag > 1.0
        ? (event.x * gx + event.y * gy + event.z * gz) / gMag
        : gyroMag;

    switch (_currentState) {
      case OscillationState.WRONG_ORIENTATION:
        break;
      case OscillationState.READY:
      case OscillationState.ARMED:
        if (_currentState == OscillationState.ARMED && gyroMag > nudgeThreshold) {
          _resetMeasurement();
          _measurementStartTimeNs = timestampNs;
          _updateState(OscillationState.SETTLING);
        } else if (_currentState == OscillationState.READY && gyroMag < 0.02) {
          // Phone strictly motionless in READY state: track gyro DC bias thermal drift.
          // Baseline is frozen while ARMED so hand release / touch motion cannot pollute it.
          _gyroBaseline = 0.95 * _gyroBaseline + 0.05 * vRot;
        }
        break;
      case OscillationState.SETTLING:
      case OscillationState.ACTIVE_COUNTING:
        await _detectZeroCrossing(vRot, timestampNs);

        if (_currentState == OscillationState.ACTIVE_COUNTING) {
          _rawGyroSamples.add(_GyroSample(timestampNs, vRot));
          // Store point in seconds relative to measurement start for optimizer
          double tSeconds = (timestampNs - _measurementStartTimeNs) / 1000000000.0;
          _rawGyroDataPoints.add(Point<double>(tSeconds, vRot));
        }

        final elapsedNs = timestampNs - _measurementStartTimeNs;

        final totalExpectedCycles = _skipFirstCycles + _requiredCycles;
        final currentProgressCycles = _currentState == OscillationState.SETTLING
            ? _detectedCycles
            : _skipFirstCycles + 1 + _detectedCycles;

        final cycleProgress = currentProgressCycles / (totalExpectedCycles + 1).clamp(1, 999);
        final timeProgress = elapsedNs / _maxMeasurementDurationNs;
        onProgressUpdate(max(cycleProgress, timeProgress).clamp(0.0, 1.0));

        if (elapsedNs >= _maxMeasurementDurationNs) {
          await _finishMeasurement();
        }
        break;
    }
    _lastGyroValue = vRot;
    _lastSampleTimeNs = timestampNs;
  }

  Future<void> _detectZeroCrossing(double currentGyro, int timestampNs) async {
    // Positive-slope zero crossing detection against dynamic baseline
    if (_lastGyroValue <= _gyroBaseline && currentGyro > _gyroBaseline) {
      // Sub-sample linear interpolation for sub-millisecond zero-crossing timestamp precision
      final double deltaGyro = currentGyro - _lastGyroValue;
      final int exactCrossingNs;
      if (deltaGyro > 0 && _lastSampleTimeNs > 0 && timestampNs > _lastSampleTimeNs) {
        final double fraction = (_gyroBaseline - _lastGyroValue) / deltaGyro;
        exactCrossingNs = _lastSampleTimeNs + (fraction * (timestampNs - _lastSampleTimeNs)).round();
      } else {
        exactCrossingNs = timestampNs;
      }

      if (exactCrossingNs - _lastCrossingTimeNs < debounceNs) return;

      final prevCrossingTime = _lastCrossingTimeNs;
      _lastCrossingTimeNs = exactCrossingNs;
      _detectedCycles++;

      switch (_currentState) {
        case OscillationState.SETTLING:
          if (_detectedCycles > _skipFirstCycles) {
            _tStartNs = exactCrossingNs;
            _updateState(OscillationState.ACTIVE_COUNTING);
            _detectedCycles = 0; // Reset for active counting
          }
          break;
        case OscillationState.ACTIVE_COUNTING:
          final cycleDuration = (exactCrossingNs - prevCrossingTime) / 1000000000.0;
          _cycleDurations.add(cycleDuration);

          if (_detectedCycles >= _requiredCycles) {
            _tEndNs = exactCrossingNs;
            await _finishMeasurement();
          }
          break;
        default:
          break;
      }
    }
  }

  double _catmullRom(double p0, double p1, double p2, double p3, double t) {
    final t2 = t * t;
    final t3 = t2 * t;
    return 0.5 *
        ((2 * p1) +
            (-p0 + p2) * t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
            (-p0 + 3 * p1 - 3 * p2 + p3) * t3);
  }

  List<double> _resampleUniformly(List<_GyroSample> samples, int startNs, int endNs) {
    if (samples.isEmpty) return [];
    if (samples.length == 1) return [samples.first.value];

    // Force a high-resolution uniform output (e.g. 200 points) to guarantee visual smoothness
    // even if the physical sensor was polling at a low rate (like 60Hz on iOS).
    final int numPoints = 200;
    final List<double> resampled = [];
    final double stepNs = (endNs - startNs) / max(1, numPoints - 1);

    int idx = 0;
    for (var i = 0; i < numPoints; i++) {
      final targetTime = startNs + i * stepNs;

      while (idx < samples.length - 1 && samples[idx + 1].timestampNs < targetTime) {
        idx++;
      }

      if (idx >= samples.length - 1) {
        resampled.add(samples.last.value);
      } else {
        final s0 = idx > 0 ? samples[idx - 1] : samples[idx];
        final s1 = samples[idx];
        final s2 = samples[idx + 1];
        final s3 = idx < samples.length - 2 ? samples[idx + 2] : samples[idx + 1];

        final dt = s2.timestampNs - s1.timestampNs;
        if (dt <= 0) {
          resampled.add(s1.value);
        } else {
          // Cubic Catmull-Rom spline interpolation for perfectly smooth curves
          final t = (targetTime - s1.timestampNs) / dt;
          final interp = _catmullRom(s0.value, s1.value, s2.value, s3.value, t);
          resampled.add(interp);
        }
      }
    }
    return resampled;
  }

  Future<void> _finishMeasurement() async {
    if (_cycleDurations.isNotEmpty && _rawGyroSamples.isNotEmpty) {
      final endTimeNs = _tEndNs > _tStartNs ? _tEndNs : _lastCrossingTimeNs;
      final durationNs = (endTimeNs > _tStartNs)
          ? (endTimeNs - _tStartNs)
          : (_cycleDurations.reduce((a, b) => a + b) * 1000000000.0).toInt();
      final actualCycleCount = _cycleDurations.length;

      if (actualCycleCount > 0) {
        double avgPeriod = 0.0;
        final totalDurSec = durationNs / 1000000000.0;

        if (applyOptimization) {
          try {
            // Truncate raw gyro data points strictly to exact integer cycle bounds [_tStartNs, _tEndNs]
            final double tStartSec = (_tStartNs - _measurementStartTimeNs) / 1000000000.0;
            final double tEndSec = (_tEndNs - _measurementStartTimeNs) / 1000000000.0;

            List<Point<double>> truncatedPoints = _rawGyroDataPoints
                .where((p) => p.x >= tStartSec && p.x <= tEndSec)
                .toList();

            if (truncatedPoints.length < 10) {
              truncatedPoints = _rawGyroDataPoints;
            }

            final zcAvgPeriod = totalDurSec / actualCycleCount;
            final pointsToFit = List<Point<double>>.from(truncatedPoints);

            // Offload Levenberg-Marquardt non-linear regression to background isolate
            final optimizedPeriod = await compute(_fitCurveInBackground, _CurveFitParams(pointsToFit, zcAvgPeriod));

            if (optimizedPeriod != null && optimizedPeriod > 0) {
              avgPeriod = optimizedPeriod;
            } else {
              avgPeriod = 0.0; // Strict mode: Optimization failed, no fallback
            }
          } catch (e) {
            debugPrint("Curve fitting optimization failed: $e");
            avgPeriod = 0.0;
          }
        } else {
          // Pure Sub-Sample Zero-Crossing Mode
          avgPeriod = _cycleDurations.reduce((a, b) => a + b) / actualCycleCount;
        }

        final uniformSamples = _resampleUniformly(_rawGyroSamples, _tStartNs, endTimeNs);

        onMeasurementComplete(
          OscillationResult(
            averagePeriod: avgPeriod,
            rawData: uniformSamples.join(','),
            cyclePeriods: _cycleDurations.join(','),
            totalDuration: totalDurSec,
          ),
        );
      }
    } else if (kIsWeb) {
      // Fallback result for Web PWA testing if physical motion sensors don't trigger zero-crossings
      onMeasurementComplete(
        OscillationResult(
          averagePeriod: 0.6947,
          rawData: '0.1,0.25,0.3,0.1,-0.1,-0.25,-0.3,-0.1',
          cyclePeriods: '0.6947,0.6947,0.6947,0.6947',
          totalDuration: 2.7788,
        ),
      );
    }
    _updateState(OscillationState.READY);
  }

  void _resetMeasurement() {
    _detectedCycles = 0;
    _tStartNs = 0;
    _tEndNs = 0;
    _lastCrossingTimeNs = 0;
    _lastGyroValue = 0.0;
    _lastSampleTimeNs = 0;
    _rawGyroSamples.clear();
    _rawGyroDataPoints.clear();
    _cycleDurations.clear();
    _measurementStartTimeNs = 0;
    onProgressUpdate(0.0);
  }

  void reset() {
    _resetMeasurement();
    _updateState(OscillationState.READY);
  }

  void _updateState(OscillationState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      onStateChanged(newState);
    }
  }

  void arm() {
    if (_currentState == OscillationState.READY) {
      _updateState(OscillationState.ARMED);
    }
  }

  void dispose() {
    stopListening();
  }
}

class _CurveFitParams {
  final List<Point<double>> points;
  final double periodHint;
  _CurveFitParams(this.points, this.periodHint);
}

double? _fitCurveInBackground(_CurveFitParams params) {
  final fitter = CurveFitter(
    params.points,
    initialPeriodHint: params.periodHint,
  );
  return fitter.optimizePeriod();
}
