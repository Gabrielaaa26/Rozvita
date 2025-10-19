# Reguli Proguard pentru aplicația ROZvita

# Păstrează informațiile despre debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Reguli pentru Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Reguli pentru Play Core Library
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Reguli pentru Bluetooth LE
-keep class no.nordicsemi.android.** { *; }
-keep class org.altbeacon.** { *; }
-dontwarn org.altbeacon.**

# Reguli Flutter generale
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Reguli pentru plugin-uri Flutter
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**
-keep public class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Reguli pentru Kotlin
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Păstrează modele de date și entități
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Reguli specifice pentru FlutterPlugin
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.android.** { *; }

# Reguli pentru Play Store Split
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
