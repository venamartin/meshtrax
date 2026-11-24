import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Saves the frame on every move/resize and restores it on next launch.
    self.setFrameAutosaveName("MainWindow")

    RegisterGeneratedPlugins(registry: flutterViewController)

    // "meshtrax/storage": excludeFromBackup(path) keeps a folder out of Time
    // Machine backups. Offline maps can be downloaded again.
    let storage = FlutterMethodChannel(
      name: "meshtrax/storage", binaryMessenger: flutterViewController.engine.binaryMessenger)
    storage.setMethodCallHandler { call, result in
      // Bytes free at path for a download the user asks for (the photo model).
      if call.method == "freeBytes", let path = call.arguments as? String {
        let url = URL(fileURLWithPath: path)
        let free = try? url.resourceValues(
          forKeys: [.volumeAvailableCapacityForImportantUsageKey]
        ).volumeAvailableCapacityForImportantUsage
        result(free.map { NSNumber(value: $0) })
        return
      }
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

    super.awakeFromNib()
  }
}
