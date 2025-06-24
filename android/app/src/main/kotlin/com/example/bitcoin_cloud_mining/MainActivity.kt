package com.example.bitcoin_cloud_mining

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import android.content.Context
import com.google.android.gms.ads.nativead.NativeAd
import io.flutter.plugins.googlemobileads.NativeAdFactory
import android.view.LayoutInflater
import android.view.View
import android.widget.TextView

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(this)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

// Example implementation of a simple native ad factory
class ListTileNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): View {
        val adView = LayoutInflater.from(context).inflate(R.layout.native_ad_list_tile, null)
        // Bind your ad assets to the view here, e.g.:
        adView.findViewById<TextView>(R.id.ad_headline).text = nativeAd.headline
        // ...bind other assets as needed...
        return adView
    }
}
