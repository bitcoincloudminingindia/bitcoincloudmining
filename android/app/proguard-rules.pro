# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter Deferred Components
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class com.google.android.play.core.common.** { *; }
-keep class com.google.android.play.core.appupdate.** { *; }
-keep class com.google.android.play.core.assetpacks.** { *; }
-dontwarn com.google.android.play.core.**

# Unity Ads
-keep class com.unity3d.ads.** { *; }
-keep class com.unity3d.services.** { *; }
-dontwarn com.unity3d.**
-dontwarn com.unity3d.ads.**
-dontwarn com.unity3d.services.**

# AdMob
-keep public class com.google.android.gms.ads.** { public *; }
-keep public class com.google.ads.mediation.admob.AdMobAdapter { *; }
-keep public class com.google.ads.mediation.admob.AdMobCustomEventBanner { *; }
-keep public class com.google.ads.mediation.admob.AdMobCustomEventInterstitial { *; }
-keep public class com.google.ads.mediation.admob.AdMobCustomEventRewarded { *; }
-keep public class com.google.ads.mediation.admob.AdMobCustomEventNative { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.inappmessaging.** { *; }
-keep class com.google.firebase.measurement.** { *; }
-dontwarn com.google.firebase.**

# GMS (Google Mobile Services)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# AndroidX
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keep class * implements androidx.lifecycle.DefaultLifecycleObserver { *; }
-keep class androidx.multidex.** { *; }

# General
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes InnerClasses
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Keep all classes that are referenced in AndroidManifest.xml
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Application
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider
-keep public class * extends android.app.backup.BackupAgentHelper
-keep public class * extends android.preference.Preference
-keep public class * extends android.view.View
-keep public class * extends android.app.Fragment
-keep public class * extends android.support.v4.app.Fragment
-keep public class * extends androidx.fragment.app.Fragment
-keep public class * extends com.google.android.material.snackbar.Snackbar$Callback
-keep public class * extends com.google.android.material.bottomsheet.BottomSheetBehavior
-keep public class * extends android.view.View$OnClickListener
-keep public class * extends android.view.View$OnTouchListener

# Keep the special static methods that are required in all enumeration classes.
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep - Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve R (resources)
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep serialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# For using GSON @SerializedName
-keepattributes Signature
-keepattributes *Annotation*
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep model classes that are serialized/deserialized over Gson
-keep class com.google.gson.** { *; }
-keep class com.google.gson.stream.** { *; }
-keep class com.google.gson.examples.android.model.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer