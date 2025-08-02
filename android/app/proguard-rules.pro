# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.ads.mediation.** { *; }

# Unity Ads
-keep class com.unity3d.** { *; }
-dontwarn com.unity3d.** 

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep your app's main classes
-keep class com.bitcoincloudmining.newapp.** { *; }
-keep class com.bitcoincloudmining.newapp.MainActivity { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum values
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep R classes
-keep class **.R$* {
    public static <fields>;
}

# Google Play Core - Missing classes (auto-generated)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# IronSource Mediation ProGuard Rules - Enhanced
-keepclassmembers class com.ironsource.sdk.controller.IronSourceWebView$JSInterface {
    public *;
}
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep class com.ironsource.adapters.** { *;
}
-keep class com.ironsource.unity.androidbridge.** { *;
}
-keep class com.ironsource.mediationsdk.** { *;
}
-keep class com.ironsource.sdk.** { *;
}
-keep class com.ironsource.adapters.** { *;
}
-dontwarn com.ironsource.mediationsdk.**
-dontwarn com.ironsource.adapters.**
-dontwarn com.ironsource.sdk.**
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# IronSource specific rules to prevent 200 errors
-keep class com.ironsource.mediationsdk.logger.IronLog { *; }
-keep class com.ironsource.mediationsdk.logger.IronSourceLogger { *; }
-keep class com.ironsource.mediationsdk.metadata.MetaData { *; }
-keep class com.ironsource.mediationsdk.model.Placement { *; }
-keep class com.ironsource.mediationsdk.model.NetworkSettings { *; }
-keep class com.ironsource.mediationsdk.impressionData.ImpressionData { *; }
-keep class com.ironsource.mediationsdk.impressionData.ImpressionDataListener { *; }

# Keep IronSource network adapters
-keep class com.ironsource.adapters.admob.** { *; }
-keep class com.ironsource.adapters.facebook.** { *; }
-keep class com.ironsource.adapters.unityads.** { *; }
-keep class com.ironsource.adapters.applovin.** { *; }

# Keep IronSource SDK classes
-keep class com.ironsource.mediationsdk.IronSource { *; }
-keep class com.ironsource.mediationsdk.ISDemandOnlyBannerLayout { *; }
-keep class com.ironsource.mediationsdk.ISDemandOnlyInterstitialListener { *; }
-keep class com.ironsource.mediationsdk.ISDemandOnlyRewardedVideoListener { *; }
-keep class com.ironsource.mediationsdk.ISDemandOnlyBannerListener { *; }