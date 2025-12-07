import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Register NFC Plugin
        if #available(iOS 11.0, *) {
            if let controller = window?.rootViewController as? FlutterViewController {
                NfcPlugin.register(with: controller.registrar(forPlugin: "NfcPlugin")!)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
