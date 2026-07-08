import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let prayerWidgetChannelName = "com.youssef.islamic_app/prayer_widget"
  private let prayerWidgetAppGroup = "group.com.example.islamicApp"
  private var pendingPrayerDeepLink = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    configurePrayerWidgetChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if isPrayerDeepLink(url) {
      pendingPrayerDeepLink = true
      return true
    }

    return super.application(application, open: url, options: options)
  }

  private func configurePrayerWidgetChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }

    let channel = FlutterMethodChannel(
      name: prayerWidgetChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }

      switch call.method {
      case "syncPrayerWidgetSnapshot":
        if let values = call.arguments as? [String: Any] {
          self.savePrayerWidgetSnapshot(values)
          if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "PrayerHomeWidget")
          }
        }
        result(nil)

      case "setPrayerLiveStatusEnabled":
        result(nil)

      case "consumeInitialPrayerDeepLink":
        let shouldOpen = self.pendingPrayerDeepLink
        self.pendingPrayerDeepLink = false
        result(shouldOpen)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func savePrayerWidgetSnapshot(_ values: [String: Any]) {
    guard let defaults = UserDefaults(suiteName: prayerWidgetAppGroup) else {
      return
    }

    for (key, value) in values {
      switch value {
      case let string as String:
        defaults.set(string, forKey: key)
      case let number as NSNumber:
        defaults.set(number, forKey: key)
      case let bool as Bool:
        defaults.set(bool, forKey: key)
      default:
        break
      }
    }

    defaults.synchronize()
  }

  private func isPrayerDeepLink(_ url: URL) -> Bool {
    return url.scheme == "islamicapp" && url.host == "prayer"
  }
}
