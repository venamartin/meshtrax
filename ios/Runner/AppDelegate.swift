import Flutter
import UIKit
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var drive: DriveFolder?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let driveRegistrar = engineBridge.pluginRegistry.registrar(forPlugin: "MeshTraxDrive") {
      drive = DriveFolder(messenger: driveRegistrar.messenger())
    }
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "MeshTraxStorage")
    else { return }
    // "meshtrax/storage": excludeFromBackup(path) keeps a folder out of iCloud
    // backups. Offline maps can be downloaded again, and Apple's storage
    // rules say such files must not be backed up.
    let storage = FlutterMethodChannel(
      name: "meshtrax/storage", binaryMessenger: registrar.messenger())
    storage.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path, isDirectory: true)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        result(FlutterError(code: "backup", message: error.localizedDescription, details: nil))
      }
    }
  }
}

/// "meshtrax/drive": a folder of offline maps for "Use a drive"
/// (lib/services/drive_folder.dart). pickFolder opens the document picker
/// on folders (Files, USB drives) and starts security-scoped access to the
/// one chosen, so the app reads it by path; stopAccess(path) ends it.
/// keepScreenOn(bool) keeps the screen awake while maps copy, as the app
/// stops when the phone locks.
final class DriveFolder: NSObject, UIDocumentPickerDelegate {
  private var pending: FlutterResult?
  private var open: [String: URL] = [:]

  init(messenger: FlutterBinaryMessenger) {
    super.init()
    let channel = FlutterMethodChannel(name: "meshtrax/drive", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "pickFolder":
      pickFolder(result)
    case "stopAccess":
      if let path = call.arguments as? String, let url = open.removeValue(forKey: path) {
        url.stopAccessingSecurityScopedResource()
      }
      result(nil)
    case "keepScreenOn":
      UIApplication.shared.isIdleTimerDisabled = (call.arguments as? Bool) ?? false
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pickFolder(_ result: @escaping FlutterResult) {
    pending?(nil)
    pending = result
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.folder])
    picker.delegate = self
    picker.allowsMultipleSelection = false
    guard let presenter = topViewController() else {
      pending = nil
      result(FlutterError(code: "drive", message: "Nothing to show the picker on", details: nil))
      return
    }
    presenter.present(picker, animated: true)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    guard let result = pending else { return }
    pending = nil
    guard let url = urls.first, url.startAccessingSecurityScopedResource() else {
      result(FlutterError(code: "drive", message: "No access to that folder", details: nil))
      return
    }
    open[url.path] = url
    result(["path": url.path, "name": url.lastPathComponent])
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pending?(nil)
    pending = nil
  }

  private func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}
