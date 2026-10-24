import 'dart:async';
import 'dart:js_interop';
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

void registerWebMotionListenerImpl(void Function(double gx, double gy, double gz, double ax, double ay, double az, double timeStampMs) onMotion) {
  unregisterWebMotionListenerImpl();

  final listener = ((web.Event event) {
    final motionEvent = event as web.DeviceMotionEvent;
    final rot = motionEvent.rotationRate;
    final acc = motionEvent.accelerationIncludingGravity;
    final ts = motionEvent.timeStamp.toDouble();

    final alpha = rot?.alpha?.toDouble() ?? 0.0;
    final beta = rot?.beta?.toDouble() ?? 0.0;
    final gamma = rot?.gamma?.toDouble() ?? 0.0;

    final gx = (alpha * 3.141592653589793) / 180.0;
    final gy = (beta * 3.141592653589793) / 180.0;
    final gz = (gamma * 3.141592653589793) / 180.0;

    final ax = acc?.x?.toDouble() ?? 0.0;
    final ay = acc?.y?.toDouble() ?? 0.0;
    final az = acc?.z?.toDouble() ?? 9.8;

    onMotion(gx, gy, gz, ax, ay, az, ts);
  }).toJS;

  _webMotionListener = listener;
  web.window.addEventListener('devicemotion', _webMotionListener);
}

void unregisterWebMotionListenerImpl() {
  if (_webMotionListener != null) {
    web.window.removeEventListener('devicemotion', _webMotionListener);
    _webMotionListener = null;
  }
}
