import Foundation
import google_mobile_ads
import UIKit
import Flutter

class ListTileNativeAdFactory: NSObject, FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: GADNativeAd,
        customOptions: [AnyHashable : Any]? = nil
    ) -> GADNativeAdView {
        let nibView = Bundle.main.loadNibNamed("ListTileNativeAdView", owner: nil, options: nil)?.first
        guard let adView = nibView as? GADNativeAdView else {
            fatalError("Could not load ListTileNativeAdView from nib")
        }

        // Example: Bind ad assets to your view's outlets here
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        adView.nativeAd = nativeAd

        // Bind other assets as needed (icon, callToAction, etc.)

        return adView
    }
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
    GoogleMobileAdsPlugin.registerNativeAdFactory(
      controller.binaryMessenger,
      factoryId: "listTile",
      nativeAdFactory: ListTileNativeAdFactory()
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
