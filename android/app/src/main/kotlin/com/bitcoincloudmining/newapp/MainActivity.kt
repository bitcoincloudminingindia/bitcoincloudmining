package com.bitcoincloudmining.newapp

import android.content.Context
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import androidx.core.view.WindowCompat
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }

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

class ListTileNativeAdFactory(private val context: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = LayoutInflater.from(context)
            .inflate(R.layout.native_ad_list_tile, null) as NativeAdView

        try {
            // Bind headline
            adView.headlineView = adView.findViewById(R.id.ad_headline)
            val headlineView = adView.headlineView as? TextView
            if (headlineView != null && nativeAd.headline != null) {
                headlineView.text = nativeAd.headline
            }

            // Bind media content (image/video)
            adView.mediaView = adView.findViewById(R.id.ad_media)
            if (nativeAd.mediaContent != null) {
                adView.mediaView?.setMediaContent(nativeAd.mediaContent)
            }

            // Bind icon if available
            adView.iconView = adView.findViewById(R.id.ad_app_icon)
            val iconView = adView.iconView as? ImageView
            val icon = nativeAd.icon
            if (icon != null && iconView != null) {
                iconView.setImageDrawable(icon.drawable)
                iconView.visibility = View.VISIBLE
            } else {
                iconView?.visibility = View.GONE
            }

            // Bind CTA button
            adView.callToActionView = adView.findViewById(R.id.ad_call_to_action)
            val ctaButton = adView.callToActionView as? Button
            if (ctaButton != null && nativeAd.callToAction != null) {
                ctaButton.text = nativeAd.callToAction
            }

            // Set the ad
            adView.setNativeAd(nativeAd)

        } catch (e: Exception) {
            // Log error but don't crash
            println("Error creating native ad: ${e.message}")
        }

        return adView
    }
}
// Note: Ensure that the layout file `native_ad_list_tile.xml` exists in the `res/layout` directory 