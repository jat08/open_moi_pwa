import 'dart:async';
import 'dart:js_interop';

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

@JS('window.addEventListener')
external void _addEventListener(String type, JSFunction listener);

@JS('window.removeEventListener')
external void _removeEventListener(String type, JSFunction listener);

@JS('window.history.pushState')
external void _pushState(JSAny? state, String title, String? url);

@JS('lockPortraitOrientation')
external void jsLockPortraitOrientation();

void pushWebHistoryStateImpl(String stateKey) {
  try {
    _pushState({'key': stateKey}.toJS, '', null);
  } catch (_) {}
}

JSFunction? _popStateListener;

void registerPopStateListenerImpl(void Function() onPop) {
  try {
    _popStateListener = (() {
      onPop();
    }).toJS;
    _addEventListener('popstate', _popStateListener!);
  } catch (_) {}
}

void lockPortraitOrientationImpl() {
  try {
    jsLockPortraitOrientation();
  } catch (_) {}
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

JSFunction? _webMotionListener;

void registerWebMotionListenerImpl(void Function(double gx, double gy, double gz, double ax, double ay, double az, double timeStampMs) onMotion) {
  unregisterWebMotionListenerImpl();
  _webMotionListener = ((_DeviceMotionEvent event) {
    final rot = event.rotationRate;
    final acc = event.accelerationIncludingGravity;
    final ts = event.timeStamp ?? 0.0;

    final alpha = rot?.alpha ?? 0.0;
    final beta = rot?.beta ?? 0.0;
    final gamma = rot?.gamma ?? 0.0;

    final gx = (alpha * 3.141592653589793) / 180.0;
    final gy = (beta * 3.141592653589793) / 180.0;
    final gz = (gamma * 3.141592653589793) / 180.0;

    final ax = acc?.x ?? 0.0;
    final ay = acc?.y ?? 0.0;
    final az = acc?.z ?? 9.8;

    onMotion(gx, gy, gz, ax, ay, az, ts);
  }).toJS;

  _addEventListener('devicemotion', _webMotionListener!);
}

void unregisterWebMotionListenerImpl() {
  if (_webMotionListener != null) {
    _removeEventListener('devicemotion', _webMotionListener!);
    _webMotionListener = null;
  }
}
