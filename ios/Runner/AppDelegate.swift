import UIKit
import Flutter
import FamilyControls

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.burnoutbuster/digital_wellbeing",
                                              binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "requestPermission" {
          if #available(iOS 15.0, *) {
              Task {
                  do {
                      try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                      result(true)
                  } catch {
                      result(FlutterError(code: "AUTH_ERROR", message: "Failed to authorize", details: nil))
                  }
              }
          } else {
              result(FlutterError(code: "UNAVAILABLE", message: "Requires iOS 15+", details: nil))
          }
      } else if call.method == "getUsageStats" {
         // Note: True usage stats are not accessible directly via API for privacy.
         // This returns mock data for the MVP to function. 
         // Real apps must use DeviceActivityReport extension to display data in a sandboxed view.
         let mockStats = [
             ["packageName": "com.apple.mobilesafari", "totalTime": 3600000], // 1 hour
             ["packageName": "com.instagram.ios", "totalTime": 1800000] // 30 mins
         ]
         result(mockStats)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
