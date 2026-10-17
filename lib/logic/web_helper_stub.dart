import 'dart:async';

Future<bool> requestWebMotionPermissionImpl() async => true;

void registerWebMotionListenerImpl(void Function(double gx, double gy, double gz, double ax, double ay, double az) onMotion) {}

void unregisterWebMotionListenerImpl() {}
