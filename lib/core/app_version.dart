class AppVersion {
  static const String appName = 'OpenMOI';
  static const String versionName = '1.1.8';
  static const int buildNumber = 18;
  static const String buildDate = '2026-10-18';

  static String get displayVersion => 'v$versionName';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
