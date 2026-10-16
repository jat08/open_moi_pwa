class AppVersion {
  static const String appName = 'OpenMOI';
  static const String versionName = '1.0.1';
  static const int buildNumber = 2;
  static const String buildDate = '2026-10-16';

  static String get displayVersion => 'v$versionName ($buildNumber)';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
