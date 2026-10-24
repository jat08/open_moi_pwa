import 'dart:async';
import 'dart:js_interop';
import 'dart:js_util' as js_util;
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

@JS('Gyroscope')
external JSFunction get _gyroscopeConstructor;

@JS('Accelerometer')
external JSFunction get _accelerometerConstructor;

JSExportedDartFunction? _webMotionListener;
JSObject? _gyroscope;
JSObject? _accelerometer;

void registerWebMotionListenerImpl(void Function(double gx, double gy, double gz, double ax, double ay, double az, double timeStampMs) onMotion) {
  unregisterWebMotionListenerImpl();

  // Feature detection for Generic Sensor API (Supported in Chrome/Android, not Safari/iOS)
  bool hasGenericSensors = js_util.hasProperty(web.window, 'Gyroscope') && 
                           js_util.hasProperty(web.window, 'Accelerometer');

  if (hasGenericSensors) {
    try {
      final config = js_util.jsify({'frequency': 100});
      _gyroscope = js_util.callConstructor(_gyroscopeConstructor, [config]) as JSObject;
      _accelerometer = js_util.callConstructor(_accelerometerConstructor, [config]) as JSObject;

      double ax = 0.0;
      double ay = 0.0;
      double az = 9.8;

      final accListener = ((web.Event e) {
        if (_accelerometer != null) {
          ax = (js_util.getProperty(_accelerometer!, 'x') as num?)?.toDouble() ?? 0.0;
          ay = (js_util.getProperty(_accelerometer!, 'y') as num?)?.toDouble() ?? 0.0;
          az = (js_util.getProperty(_accelerometer!, 'z') as num?)?.toDouble() ?? 9.8;
        }
      }).toJS;
      (_accelerometer as web.EventTarget).addEventListener('reading', accListener);
      js_util.callMethod(_accelerometer!, 'start', []);

      final gyroListener = ((web.Event e) {
        if (_gyroscope != null) {
          final gx = (js_util.getProperty(_gyroscope!, 'x') as num?)?.toDouble() ?? 0.0;
          final gy = (js_util.getProperty(_gyroscope!, 'y') as num?)?.toDouble() ?? 0.0;
          final gz = (js_util.getProperty(_gyroscope!, 'z') as num?)?.toDouble() ?? 0.0;
          final ts = (js_util.getProperty(_gyroscope!, 'timestamp') as num?)?.toDouble() ?? 0.0;

          onMotion(gx, gy, gz, ax, ay, az, ts);
        }
      }).toJS;
      (_gyroscope as web.EventTarget).addEventListener('reading', gyroListener);
      js_util.callMethod(_gyroscope!, 'start', []);

      _webMotionListener = null; // Mark that we aren't using DeviceMotionEvent
      return;
    } catch (e) {
      // Fallback if sensor creation fails (e.g. strict Permissions-Policy)
    }
  }

  // Fallback to DeviceMotionEvent (Used by iOS Safari)
  _webMotionListener = ((web.Event event) {
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

  web.window.addEventListener('devicemotion', _webMotionListener);
}

void unregisterWebMotionListenerImpl() {
  if (_gyroscope != null) {
    js_util.callMethod(_gyroscope!, 'stop', []);
    _gyroscope = null;
  }
  if (_accelerometer != null) {
    js_util.callMethod(_accelerometer!, 'stop', []);
    _accelerometer = null;
  }

  if (_webMotionListener != null) {
    web.window.removeEventListener('devicemotion', _webMotionListener);
    _webMotionListener = null;
  }
}
