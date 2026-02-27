# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# TFLite Flutter
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-dontwarn org.tensorflow.lite.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat { *; }

# just_audio
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# vibration
-keep class com.benjaminabel.vibration.** { *; }

# wakelock_plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Gson (used by some plugins)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator CREATOR;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Play Core (referenced by Flutter engine, not used directly)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Desugaring
-dontwarn java.lang.invoke.**
-dontwarn **$$Lambda$*
