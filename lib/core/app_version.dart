class AppVersion {
  static const String appName = 'OpenMOI';
  static const String versionName = '1.1.6';
  static const int buildNumber = 16;
  static const String buildDate = '2026-10-17';

  static String get displayVersion => 'v$versionName';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
