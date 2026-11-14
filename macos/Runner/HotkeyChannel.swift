import Carbon
import Cocoa
import FlutterMacOS

/// Глобальная горячая клавиша (подключить/отключить VPN) из Dart:
///   register{key, ctrl, alt, shift, meta} → Bool — назначить вместо прежней;
///   unregister                            — снять.
/// Обратно в Dart идёт pressed.
///
/// Carbon RegisterEventHotKey, а не NSEvent.addGlobalMonitor: монитору нужно
/// разрешение «Универсальный доступ», и он не глотает нажатие, а Carbon-хоткей
/// работает без разрешений и не доходит до активного приложения.
class HotkeyChannel: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private var hotKeyRef: EventHotKeyRef?
  private var handlerRef: EventHandlerRef?

  /// Сигнатура 'VRGE' — отличает наши хоткеи от чужих в общем обработчике.
  private static let signature: OSType = 0x5652_4745
  private static weak var current: HotkeyChannel?

  init(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "verge/hotkey", binaryMessenger: registrar.messenger)
    let instance = HotkeyChannel(channel: channel)
    registrar.addMethodCallDelegate(instance, channel: channel)
    retained = instance
    current = instance
  }

  private static var retained: HotkeyChannel?

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "register":
      let args = call.arguments as? [String: Any] ?? [:]
      guard let key = args["key"] as? String, let code = Self.keyCodes[key] else {
        result(false)
        return
      }
      var modifiers: UInt32 = 0
      if args["ctrl"] as? Bool == true { modifiers |= UInt32(controlKey) }
      if args["alt"] as? Bool == true { modifiers |= UInt32(optionKey) }
      if args["shift"] as? Bool == true { modifiers |= UInt32(shiftKey) }
      if args["meta"] as? Bool == true { modifiers |= UInt32(cmdKey) }
      result(register(keyCode: code, modifiers: modifiers))
    case "unregister":
      unregister()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func register(keyCode: Int, modifiers: UInt32) -> Bool {
    unregister()
    installHandlerIfNeeded()
    let id = EventHotKeyID(signature: Self.signature, id: 1)
    var ref: EventHotKeyRef?
    let status = RegisterEventHotKey(
      UInt32(keyCode), modifiers, id, GetApplicationEventTarget(), 0, &ref)
    guard status == noErr, let ref else { return false }
    hotKeyRef = ref
    return true
  }

  private func unregister() {
    if let ref = hotKeyRef {
      UnregisterEventHotKey(ref)
      hotKeyRef = nil
    }
  }

  private func installHandlerIfNeeded() {
    guard handlerRef == nil else { return }
    var spec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    // C-колбэк ничего не захватывает — до канала добираемся через статик.
    InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, _ -> OSStatus in
        var id = EventHotKeyID()
        let status = GetEventParameter(
          event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
          nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
        guard status == noErr, id.signature == HotkeyChannel.signature else {
          return OSStatus(eventNotHandledErr)
        }
        DispatchQueue.main.async {
          HotkeyChannel.current?.channel.invokeMethod("pressed", arguments: nil)
        }
        return noErr
      },
      1, &spec, nil, &handlerRef)
  }

  /// Имена клавиш из lib/app/hotkey.dart → виртуальные коды Carbon
  /// (физическое положение клавиши, от раскладки не зависят).
  private static let keyCodes: [String: Int] = [
    "A": kVK_ANSI_A, "B": kVK_ANSI_B, "C": kVK_ANSI_C, "D": kVK_ANSI_D,
    "E": kVK_ANSI_E, "F": kVK_ANSI_F, "G": kVK_ANSI_G, "H": kVK_ANSI_H,
    "I": kVK_ANSI_I, "J": kVK_ANSI_J, "K": kVK_ANSI_K, "L": kVK_ANSI_L,
    "M": kVK_ANSI_M, "N": kVK_ANSI_N, "O": kVK_ANSI_O, "P": kVK_ANSI_P,
    "Q": kVK_ANSI_Q, "R": kVK_ANSI_R, "S": kVK_ANSI_S, "T": kVK_ANSI_T,
    "U": kVK_ANSI_U, "V": kVK_ANSI_V, "W": kVK_ANSI_W, "X": kVK_ANSI_X,
    "Y": kVK_ANSI_Y, "Z": kVK_ANSI_Z,
    "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
    "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
    "8": kVK_ANSI_8, "9": kVK_ANSI_9,
    "F1": kVK_F1, "F2": kVK_F2, "F3": kVK_F3, "F4": kVK_F4,
    "F5": kVK_F5, "F6": kVK_F6, "F7": kVK_F7, "F8": kVK_F8,
    "F9": kVK_F9, "F10": kVK_F10, "F11": kVK_F11, "F12": kVK_F12,
    "Space": kVK_Space,
  ]
}
