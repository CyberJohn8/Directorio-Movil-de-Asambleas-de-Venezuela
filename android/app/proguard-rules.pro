# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences { *; }

# Hive
-keep class com.hivedb.** { *; }

# Flutter TTS
-keep class com.tundralabs.fluttertts.** { *; }

# ===== PLAY CORE RULES =====
# Mantener clases de Play Core
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# No advertir sobre clases faltantes de Play Core
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Mantener clases de Flutter Play Store
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }

# Keep your model classes
-keep class com.example.directorio_asambleas.models.** { *; }
-keep class com.example.directorio_asambleas.entities.** { *; }

# Keep generic signatures
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable