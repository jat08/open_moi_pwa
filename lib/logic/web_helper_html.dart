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

extension type _DeviceMotionEvent(JSObject _) implements JSObject {
  external _DeviceAcceleration? get accelerationIncludingGravity;
  external _DeviceRotationRate? get rotationRate;
  external double? get timeStamp;
}

extension type _DeviceAcceleration(JSObject _) implements JSObject {
  external double? get x;
  external double? get y;
  external double? get z;
}

extension type _DeviceRotationRate(JSObject _) implements JSObject {
  external double? get alpha;
  external double? get beta;
  external double? get gamma;
}

JSExportedDartFunction? _webMotionListener;
JSExportedDartFunction? _webOrientationListener;

double _latestAx = 0.0;
double _latestAy = 0.0;
double _latestAz = 9.8;
double _latestGx = 0.0;
double _latestGy = 0.0;
double _latestGz = 0.0;
bool _hasValidMotionAcc = false;

void registerWebMotionListenerImpl(void Function(double gx, double gy, double gz, double ax, double ay, double az, double timeStampMs) onMotion) {
  unregisterWebMotionListenerImpl();

  _hasValidMotionAcc = false;
  _latestAx = 0.0;
  _latestAy = 0.0;
  _latestAz = 9.8;
  _latestGx = 0.0;
  _latestGy = 0.0;
  _latestGz = 0.0;

  // 1. DeviceOrientation listener provides pitch (beta) and roll (gamma) angles natively
  // on 100% of mobile browsers (Android Chrome & iOS Safari).
  _webOrientationListener = ((web.Event event) {
    final orientEvent = event as web.DeviceOrientationEvent;
    final beta = orientEvent.beta?.toDouble() ?? 0.0;
    final gamma = orientEvent.gamma?.toDouble() ?? 0.0;
    final ts = orientEvent.timeStamp.toDouble();

    final rBeta = (beta * pi) / 180.0;
    final rGamma = (gamma * pi) / 180.0;

    final orientAx = 9.81 * sin(rGamma);
    final orientAy = 9.81 * sin(rBeta) * cos(rGamma);
    final orientAz = 9.81 * cos(rBeta) * cos(rGamma);

    if (!_hasValidMotionAcc) {
      _latestAx = orientAx;
      _latestAy = orientAy;
      _latestAz = orientAz;
    }

    onMotion(_latestGx, _latestGy, _latestGz, _latestAx, _latestAy, _latestAz, ts);
  }).toJS;

  web.window.addEventListener('deviceorientation', _webOrientationListener);

  // 2. DeviceMotion listener provides rotation rate (gyroscope) and acceleration including gravity.
  _webMotionListener = ((_DeviceMotionEvent event) {
    final rot = event.rotationRate;
    final acc = event.accelerationIncludingGravity;
    final ts = event.timeStamp ?? 0.0;

    final alpha = rot?.alpha ?? 0.0;
    final beta = rot?.beta ?? 0.0;
    final gamma = rot?.gamma ?? 0.0;

    _latestGx = (alpha * pi) / 180.0;
    _latestGy = (beta * pi) / 180.0;
    _latestGz = (gamma * pi) / 180.0;

    final rawAx = acc?.x;
    final rawAy = acc?.y;
    final rawAz = acc?.z;

    if (rawAx != null && rawAy != null && rawAz != null) {
      final gMag = sqrt(rawAx * rawAx + rawAy * rawAy + rawAz * rawAz);
      if (gMag > 1.0) {
        _hasValidMotionAcc = true;
        _latestAx = rawAx;
        _latestAy = rawAy;
        _latestAz = rawAz;
      }
    }

    onMotion(_latestGx, _latestGy, _latestGz, _latestAx, _latestAy, _latestAz, ts);
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
