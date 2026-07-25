import FlutterMacOS
import Foundation
import AppKit

/// MethodChannel app/deeplink — доставка открытий URL-схемы `verge://` в Flutter.
/// macOS присылает открытие схемы как Apple Event kAEGetURL. Ссылка,
/// пришедшая до готовности Flutter (холодный старт), буферизируется и
/// отдаётся по запросу getInitialLink.
final class DeepLinkChannel: NSObject {
  private var channel: FlutterMethodChannel?
  private var pendingLink: String?

  func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "app/deeplink", binaryMessenger: registrar.messenger)
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getInitialLink":
        result(self?.pendingLink)
        self?.pendingLink = nil
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    // Обработчик открытия URL-схемы.
    NSAppleEventManager.shared().setEventHandler(
      self,
      andSelector: #selector(handleGetURL(event:replyEvent:)),
      forEventClass: AEEventClass(kInternetEventClass),
      andEventID: AEEventID(kAEGetURL))
  }

  @objc private func handleGetURL(event: NSAppleEventDescriptor,
                                  replyEvent: NSAppleEventDescriptor) {
    guard let urlString = event
      .paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?
      .stringValue else { return }
    if let channel = channel {
      channel.invokeMethod("onLink", arguments: urlString)
    } else {
      pendingLink = urlString
    }
  }
}
