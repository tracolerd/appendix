import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "org.appendix.appendix/ime"
  private let appGroupSuite = "group.org.appendix.appendix"
  private let keyDialect = "dialect"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppendixImePlugin")
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      let defaults = UserDefaults(suiteName: self.appGroupSuite)

      switch call.method {
      case "isImeEnabled":
        // iOS sandboxing prevents querying system-wide active third-party keyboards directly.
        // We report whether the user has interacted with the extension or configured it.
        result(defaults?.bool(forKey: "keyboard_activated") ?? true)
      case "isImeSelected":
        result(true)
      case "openImeSettings":
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
           UIApplication.shared.canOpenURL(settingsUrl) {
          UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
          result(true)
        } else {
          result(false)
        }
      case "openImePicker":
        result(true)
      case "setDialect":
        if let args = call.arguments as? [String: Any],
           let dialect = args["dialect"] as? Int {
          defaults?.set(dialect, forKey: self.keyDialect)
          result(true)
        } else {
          result(false)
        }
      case "getDialect":
        let dialect = defaults?.integer(forKey: self.keyDialect) ?? 0
        result(dialect)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
