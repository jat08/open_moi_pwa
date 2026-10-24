import 'dart:async';
import 'dart:js_interop';
import 'dart:math';
import 'package:web/web.dart' as web;

@JS('requestMotionPermission')
external JSPromise<JSBoolean> jsRequestMotionPermission();

Future<bool> requestWebMotionPermissionImpl() async {
  try {
    final promise = jsRequestMotionPermission();
    final result = await promise.toDart;
    return result.toDart;
  } catch (e) {
    return true;
  }
}

JSExportedDartFunction? _webMotionListener;
JSExportedDartFunction? _webOrientationListener;

double _latestAx = 0.0;
double _latestAy = 0.0;
double _latestAz = 9.8;
bool _hasValidMotionAcc = false;

void registerWebMotionListenerImpl(void Function(double gx, double gy, double gz, double ax, double ay, double az, double timeStampMs) onMotion) {
  unregisterWebMotionListenerImpl();

  _hasValidMotionAcc = false;
  _latestAx = 0.0;
  _latestAy = 0.0;
  _latestAz = 9.8;

  // 1. DeviceOrientation listener provides pitch (beta) and roll (gamma) angles natively
  // on 100% of mobile browsers (Android Chrome & iOS Safari).
  _webOrientationListener = ((web.Event event) {
    final orientEvent = event as web.DeviceOrientationEvent;
    final beta = orientEvent.beta?.toDouble() ?? 0.0;
    final gamma = orientEvent.gamma?.toDouble() ?? 0.0;

    if (!_hasValidMotionAcc) {
      final rBeta = (beta * pi) / 180.0;
      final rGamma = (gamma * pi) / 180.0;

      _latestAx = 9.81 * sin(rGamma);
      _latestAy = 9.81 * sin(rBeta) * cos(rGamma);
      _latestAz = 9.81 * cos(rBeta) * cos(rGamma);
    }
  }).toJS;

  web.window.addEventListener('deviceorientation', _webOrientationListener);

  // 2. DeviceMotion listener provides rotation rate (gyroscope) and acceleration including gravity.
  _webMotionListener = ((web.Event event) {
    final motionEvent = event as web.DeviceMotionEvent;
    final rot = motionEvent.rotationRate;
    final acc = motionEvent.accelerationIncludingGravity;
    final ts = motionEvent.timeStamp.toDouble();

    final alpha = rot?.alpha?.toDouble() ?? 0.0;
    final beta = rot?.beta?.toDouble() ?? 0.0;
    final gamma = rot?.gamma?.toDouble() ?? 0.0;

    final gx = (alpha * pi) / 180.0;
    final gy = (beta * pi) / 180.0;
    final gz = (gamma * pi) / 180.0;

    final rawAx = acc?.x?.toDouble();
    final rawAy = acc?.y?.toDouble();
    final rawAz = acc?.z?.toDouble();

    if (rawAx != null && rawAy != null && rawAz != null) {
      final gMag = sqrt(rawAx * rawAx + rawAy * rawAy + rawAz * rawAz);
      if (gMag > 1.0) {
        _hasValidMotionAcc = true;
        _latestAx = rawAx;
        _latestAy = rawAy;
        _latestAz = rawAz;
      }
    }

    onMotion(gx, gy, gz, _latestAx, _latestAy, _latestAz, ts);
  }).toJS;

  web.window.addEventListener('devicemotion', _webMotionListener);
}

void unregisterWebMotionListenerImpl() {
  if (_webMotionListener != null) {
    web.window.removeEventListener('devicemotion', _webMotionListener);
    _webMotionListener = null;
  }
  if (_webOrientationListener != null) {
    web.window.removeEventListener('deviceorientation', _webOrientationListener);
    _webOrientationListener = null;
  }
}
