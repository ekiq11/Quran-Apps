# android/app/proguard-rules.pro - CLEAN RULES FOR QURAN APP

# ========== FLUTTER CORE ==========
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ========== FLUTTER LOCAL NOTIFICATIONS ==========
# Keep notification classes for prayer time reminders
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.**

# Keep notification receivers
-keep class * extends android.content.BroadcastReceiver {
    public <init>(...);
}

# ========== ANDROID X ==========
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Keep core components
-keep class androidx.core.** { *; }
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.core.**
-dontwarn androidx.lifecycle.**

# ========== KOTLIN ==========
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ========== LOCATION & GEOLOCATOR ==========
# Keep location classes for prayer times calculation
-keep class com.google.android.gms.location.** { *; }
-dontwarn com.google.android.gms.**

# ========== TIMEZONE DATA ==========
# Keep timezone classes for accurate prayer times
-keep class org.threeten.** { *; }
-dontwarn org.threeten.**

# Keep timezone database
-keep class java.time.** { *; }
-dontwarn java.time.**

# ========== HTTP & NETWORKING ==========
# Keep HTTP classes for data download
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ========== GSON / JSON ==========
# Keep JSON parsing for Quran data
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# Keep JSON models
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ========== SHARED PREFERENCES ==========
-keep class android.content.SharedPreferences { *; }
-keep class * implements android.content.SharedPreferences { *; }

# ========== SQFLITE DATABASE ==========
# Keep database classes for local storage
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Keep SQLite
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# ========== PERMISSIONS ==========
# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ========== PACKAGE INFO ==========
# Keep for version checking
-keep class io.flutter.plugins.packageinfo.** { *; }
-dontwarn io.flutter.plugins.packageinfo.**

# ========== PATH PROVIDER ==========
# Keep for file storage
-keep class io.flutter.plugins.pathprovider.** { *; }
-dontwarn io.flutter.plugins.pathprovider.**

# ========== URL LAUNCHER ==========
# Keep for external links
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**

# ========== SHARE PLUS ==========
# Keep for sharing functionality
-keep class dev.fluttercommunity.plus.share.** { *; }
-dontwarn dev.fluttercommunity.plus.share.**

# ========== CONNECTIVITY PLUS ==========
# Keep for network status
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# ========== ASSET FILES ==========
# Keep assets from being stripped
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep R class
-keepclassmembers class **.R$* {
    public static <fields>;
}

# ========== SERIALIZATION ==========
# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ========== REFLECTION ==========
# Keep classes that use reflection
-keepattributes InnerClasses
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# ========== NATIVE METHODS ==========
-keepclasseswithmembernames class * {
    native <methods>;
}

# ========== ENUMS ==========
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ========== PARCELABLE ==========
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ========== CUSTOM APP CLASSES ==========
# ⚠️ IMPORTANT: Replace with your actual package name
-keep class com.bekalsunnah.doa_harian.** { *; }
-keep class com.bekalsunnah.doa_harian.MainActivity { *; }

# Keep BuildConfig
-keep class **.BuildConfig { *; }

# ========== PRAYER TIME LIBRARIES ==========
# Keep prayer calculation classes
-keep class com.batoulapps.adhan.** { *; }
-dontwarn com.batoulapps.adhan.**

# ========== OPTIMIZATION SETTINGS ==========
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# ========== WARNINGS SUPPRESSION ==========
# Suppress non-critical warnings
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn edu.umd.cs.findbugs.annotations.**
-dontwarn org.codehaus.mojo.animal_sniffer.**

# ========== GOOGLE PLAY SERVICES ==========
# Keep only if using Play Services
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# ========== ATTRIBUTES ==========
# Keep important attributes
-keepattributes SourceFile,LineNumberTable
-keepattributes LocalVariableTable
-keepattributes LocalVariableTypeTable

# For debugging
-renamesourcefileattribute SourceFile

# ========== END OF RULES ==========