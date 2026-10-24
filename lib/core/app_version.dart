class AppVersion {
  static const String appName = 'OpenMOI WebApp';
  static const String versionName = '1.2.19';
  static const int buildNumber = 39;
  static const String buildDate = '2026-10-23';

  static String get displayVersion => 'v$versionName';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
