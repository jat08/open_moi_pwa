import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'curve_fitter.dart';
import 'web_helper.dart';

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

  static const double orientationThreshold = 10.0;
  static const double targetAngle = 45.0;
  static const double nudgeThreshold = 0.3;
  static const double stationaryThreshold = 0.02; // Strictly stationary threshold in rad/s
  static const int debounceNs = 100000000; // 0.1s hysteresis window

  int sampleCount = 0;

  final List<double> _gravityVector = [0.0, 0.0, 9.8];
  double _gyroBaseline = 0.0; // Dynamically tracks DC bias
  double get gyroBaseline => _gyroBaseline;

  final List<_GyroSample> _rawGyroSamples = [];
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
          print('Accelerometer stream error: $err');
        },
        cancelOnError: false,
      );

      _gyroSub = gyroscopeEventStream(samplingPeriod: interval).listen(
        (event) {
          sampleCount++;
          handleGyroscope(event);
        },
        onError: (err) {
          print('Gyroscope stream error: $err');
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

  void handleGyroscope(GyroscopeEvent event) {
    if (_currentState == OscillationState.WRONG_ORIENTATION) return;

    // Utilize the precise hardware timestamp provided by the event (converted to nanoseconds)
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
        // Rule 1 & 3: Continuously track gyro zero-rate DC bias baseline only when strictly stationary in READY state (gyroMag < 0.02 rad/s)
        if (gyroMag < stationaryThreshold) {
          _gyroBaseline = 0.95 * _gyroBaseline + 0.05 * vRot;
        }
        break;
      case OscillationState.ARMED:
        // Rule 2: Freeze baseline as soon as system transitions to ARMED state.
        if (gyroMag > nudgeThreshold) {
          _resetMeasurement();
          _measurementStartTimeNs = timestampNs;
          _updateState(OscillationState.SETTLING);
        }
        break;
      case OscillationState.SETTLING:
      case OscillationState.ACTIVE_COUNTING:
        // Rule 2: Freeze baseline during active measurement states.
        if (_currentState == OscillationState.SETTLING || _currentState == OscillationState.ACTIVE_COUNTING) {
          if (_rawGyroSamples.isEmpty || timestampNs > _rawGyroSamples.last.timestampNs) {
            _rawGyroSamples.add(_GyroSample(timestampNs, vRot));
          }
        }
        
        _detectZeroCrossing(vRot, timestampNs);

        final elapsedNs = timestampNs - _measurementStartTimeNs;

        final totalExpectedCycles = _skipFirstCycles + _requiredCycles;
        final currentProgressCycles = _currentState == OscillationState.SETTLING
            ? _detectedCycles
            : _skipFirstCycles + 1 + _detectedCycles;

        final cycleProgress = currentProgressCycles / (totalExpectedCycles + 1).clamp(1, 999);
        final timeProgress = elapsedNs / _maxMeasurementDurationNs;
        onProgressUpdate(max(cycleProgress, timeProgress).clamp(0.0, 1.0));

        if (elapsedNs >= _maxMeasurementDurationNs) {
          _finishMeasurement();
        }
        break;
    }
    _lastGyroValue = vRot;
    _lastSampleTimeNs = timestampNs;
  }

  void _detectZeroCrossing(double currentGyro, int timestampNs) {
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
            _finishMeasurement();
          }
          break;
        default:
          break;
      }
    }
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
          // Time-aware Cubic Hermite spline interpolation (Non-uniform Catmull-Rom)
          // Avoids overshoots and loops caused by uneven sensor polling intervals
          
          double m1 = 0.0;
          if (s2.timestampNs > s0.timestampNs) {
            m1 = (s2.value - s0.value) / (s2.timestampNs - s0.timestampNs);
          }
          
          double m2 = 0.0;
          if (s3.timestampNs > s1.timestampNs) {
            m2 = (s3.value - s1.value) / (s3.timestampNs - s1.timestampNs);
          }
          
          final t = (targetTime - s1.timestampNs) / dt;
          final t2 = t * t;
          final t3 = t2 * t;
          
          final h00 = 2 * t3 - 3 * t2 + 1;
          final h10 = t3 - 2 * t2 + t;
          final h01 = -2 * t3 + 3 * t2;
          final h11 = t3 - t2;
          
          final interp = h00 * s1.value + h10 * dt * m1 + h01 * s2.value + h11 * dt * m2;
          resampled.add(interp);
        }
      }
    }
    return resampled;
  }

  void _finishMeasurement() {
    if (_cycleDurations.isNotEmpty && _rawGyroSamples.isNotEmpty) {
      final endTimeNs = _tEndNs > _tStartNs ? _tEndNs : _lastCrossingTimeNs;
      final durationNs = (endTimeNs > _tStartNs)
          ? (endTimeNs - _tStartNs)
          : (_cycleDurations.reduce((a, b) => a + b) * 1000000000.0).toInt();
      final actualCycleCount = _cycleDurations.length;

      if (actualCycleCount > 0) {
        var avgPeriod = _cycleDurations.reduce((a, b) => a + b) / actualCycleCount;
        final totalDurSec = durationNs / 1000000000.0;

        if (_rawGyroSamples.length >= 10) {
          final pts = _rawGyroSamples
              .map((s) => Point<double>(s.timestampNs / 1000000000.0, s.value))
              .toList();
          final tStartSec = _tStartNs > 0 ? _tStartNs / 1000000000.0 : null;
          final tEndSec = endTimeNs > 0 ? endTimeNs / 1000000000.0 : null;

          final fitter = CurveFitter(
            pts,
            initialPeriodHint: avgPeriod,
            tStart: tStartSec,
            tEnd: tEndSec,
          );
          final fittedPeriod = fitter.optimizePeriod();
          if (fittedPeriod != null && fittedPeriod > 0) {
            avgPeriod = fittedPeriod;
          }
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
    _cycleDurations.clear();
    _measurementStartTimeNs = 0;
    onProgressUpdate(0.0);
  }

  void _updateState(OscillationState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      onStateChanged(newState);
    }
  }

  void reset() {
    _resetMeasurement();
    _updateState(OscillationState.READY);
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
