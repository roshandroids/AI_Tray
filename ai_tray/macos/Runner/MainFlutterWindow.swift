import Cocoa
import FlutterMacOS
import ServiceManagement

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // launch_at_startup uses a manual channel on macOS (not a generated plugin).
    // SMAppService is the supported Login Item API on macOS 13+.
    FlutterMethodChannel(
      name: "launch_at_startup",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    ).setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      Self.handleLaunchAtStartup(call: call, result: result)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private static func handleLaunchAtStartup(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard #available(macOS 13.0, *) else {
      result(
        FlutterError(
          code: "unsupported",
          message: "Launch at login requires macOS 13 or later",
          details: nil
        )
      )
      return
    }

    switch call.method {
    case "launchAtStartupIsEnabled":
      result(SMAppService.mainApp.status == .enabled)
    case "launchAtStartupSetEnabled":
      guard
        let arguments = call.arguments as? [String: Any],
        let setEnabled = arguments["setEnabledValue"] as? Bool
      else {
        result(
          FlutterError(
            code: "bad_args",
            message: "setEnabledValue Bool required",
            details: nil
          )
        )
        return
      }
      do {
        if setEnabled {
          if SMAppService.mainApp.status != .enabled {
            try SMAppService.mainApp.register()
          }
        } else if SMAppService.mainApp.status == .enabled {
          try SMAppService.mainApp.unregister()
        }
        result(nil)
      } catch {
        result(
          FlutterError(
            code: "sm_error",
            message: error.localizedDescription,
            details: nil
          )
        )
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
