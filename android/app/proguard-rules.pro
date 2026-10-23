# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep MainActivity and custom MethodChannel callbacks
-keep class com.openmoi.open_moi_cp.MainActivity { *; }

# Keep SQLite classes for sqflite plugin
-keep class org.sqlite.** { *; }
-keep class io.flutter.plugins.sqflite.** { *; }

# Keep Sensors and NFC plugin classes
-keep class dev.fluttercommunity.plus.sensors.** { *; }
-keep class io.flutter.plugins.nfcmanager.** { *; }

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses

-dontwarn io.flutter.embedding.**
