class AppVersion {
  static const String appName = 'OpenMOI WebApp';
  static const String versionName = '1.2.4';
  static const int buildNumber = 24;
  static const String buildDate = '2026-10-19';

  static String get displayVersion => 'v$versionName';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
