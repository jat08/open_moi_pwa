class AppVersion {
  static const String appName = 'OpenMOI';
  static const String versionName = '1.0.9';
  static const int buildNumber = 10;
  static const String buildDate = '2026-10-16';

  static String get displayVersion => 'v$versionName';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
