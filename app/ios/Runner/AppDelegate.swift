import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "org.appendix.appendix/ime"
  private let keyDialect = "dialect"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppendixImePlugin") else { return }
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard let self = self else { return }
      let defaults = UserDefaults.standard

      switch call.method {
      case "isImeEnabled":
        // Apple iOS security sandboxing prevents containing apps from querying
        // whether custom keyboards are enabled in Settings > General > Keyboard.
        // We report false so the UI directs the user to the iOS Settings guide.
        result(false)
      case "isImeSelected":
        // iOS does not reveal the currently active keyboard to container apps.
        result(false)
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
          defaults.set(dialect, forKey: self.keyDialect)
          result(true)
        } else {
          result(false)
        }
      case "getDialect":
        let dialect = defaults.integer(forKey: self.keyDialect)
        result(dialect)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
