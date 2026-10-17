import 'web_helper_stub.dart'
    if (dart.library.js_interop) 'web_helper_html.dart';

Future<bool> requestWebMotionPermission() => requestWebMotionPermissionImpl();

void registerWebMotionListener(void Function(double gx, double gy, double gz, double ax, double ay, double az) onMotion) =>
    registerWebMotionListenerImpl(onMotion);

void unregisterWebMotionListener() => unregisterWebMotionListenerImpl();
