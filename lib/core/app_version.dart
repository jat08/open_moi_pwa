class AppVersion {
  static const String appName = 'OpenMOI WebApp';
  static const String versionName = '1.2.13';
  static const int buildNumber = 33;
  static const String buildDate = '2026-10-21';

  static String get displayVersion => 'v$versionName';
  static String get fullVersionNote => '$appName $displayVersion';
  static String get copyrightNote => '© 2026 OpenMOI Project';
}
