import Flutter
import UIKit
import Valhalla

/// Offline routing with Valhalla as a library (valhalla-mobile). Dart writes the config and the
/// requests (packages/traxroute, ValhallaMobileEngine); this only opens the config and runs the
/// requests, one at a time, off the main thread.
public class TraxrouteIosPlugin: NSObject, FlutterPlugin {
  private let queue = DispatchQueue(label: "meshtrax.routing")

  // Touched only on `queue`.
  private var valhalla: Valhalla?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "meshtrax/routing", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(TraxrouteIosPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let argument = call.arguments as? String ?? ""
    switch call.method {
    case "open":
      run(result) {
        self.closeEngine()
        self.valhalla = try Valhalla(configPath: argument)
        return nil
      }
    case "route":
      run(result) { try self.route(argument) }
    case "close":
      run(result) {
        self.closeEngine()
        return nil
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Valhalla's JSON, or its refusal in the shape its service answers with.
  private func route(_ request: String) throws -> String {
    guard let engine = valhalla else { throw RoutingError.notOpen }
    do {
      return try engine.route(rawRequest: request)
    } catch ValhallaError.valhallaError(_, let message) {
      let body = try JSONSerialization.data(withJSONObject: ["error": message])
      return String(decoding: body, as: UTF8.self)
    }
  }

  private func closeEngine() {
    valhalla?.close()
    valhalla = nil
  }

  private func run(_ result: @escaping FlutterResult, _ work: @escaping () throws -> String?) {
    queue.async {
      do {
        let answer = try work()
        DispatchQueue.main.async { result(answer) }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(code: "routing", message: error.localizedDescription, details: nil))
        }
      }
    }
  }
}

private enum RoutingError: LocalizedError {
  case notOpen

  var errorDescription: String? { "No routing data open" }
}
