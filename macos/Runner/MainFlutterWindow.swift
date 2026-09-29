import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Крестик сворачивает в трей вместо завершения процесса — VPN должен
    // продолжать работать в фоне. Делегат — сама MainFlutterWindow, а не
    // сторонний пакет: window_manager отдавал этот же результат ненадёжно
    // (гонка между установкой его делегата из Dart и реальным кликом).
    // Полностью завершает работу только «Закрыть» в трее или Cmd+Q — оба идут
    // в обход windowShouldClose (Cmd+Q — через applicationShouldTerminate).
    self.delegate = self

    super.awakeFromNib()
  }

  func windowShouldClose(_ sender: NSWindow) -> Bool {
    if inPopover {
      exitPopover(showMain: false, notify: true)
    } else {
      sender.orderOut(nil)
    }
    return false
  }

  // MARK: - Мини-окно трея
  //
  // Второго окна нет: по клику в строке меню это же окно становится
  // компактным (без заголовка, поверх всех) под значком, а Flutter рисует в
  // нём мини-интерфейс (lib/ui/tray_popover.dart). Потеря фокуса или
  // «Открыть Verge» возвращают окну прежний вид.

  private(set) var inPopover = false
  private var savedFrame = NSRect.zero
  private var savedStyle: NSWindow.StyleMask = []
  private var savedLevel: NSWindow.Level = .normal
  private var savedTitleVisibility: NSWindow.TitleVisibility = .visible
  private var savedTitlebarTransparent = false
  private var savedMovable = true
  private var wasVisible = false

  /// Зовётся, когда мини-окно закрылось не по команде из Dart (клик мимо,
  /// Cmd+W, «Открыть» из меню) — чтобы Dart вернул главный интерфейс.
  var onPopoverDismissed: (() -> Void)?

  private static let titleButtons: [NSWindow.ButtonType] =
      [.closeButton, .miniaturizeButton, .zoomButton]

  func showPopover(size: NSSize) {
    if !inPopover {
      savedFrame = frame
      savedStyle = styleMask
      savedLevel = level
      savedTitleVisibility = titleVisibility
      savedTitlebarTransparent = titlebarAppearsTransparent
      savedMovable = isMovable
      wasVisible = isVisible
      inPopover = true
      // Заголовок прячем, но окно оставляем .titled: так оно может стать
      // key (нужно для клавиатуры и для закрытия по потере фокуса) и
      // сохраняет системные скругления и тень.
      styleMask = [.titled, .fullSizeContentView]
      titleVisibility = .hidden
      titlebarAppearsTransparent = true
      for button in Self.titleButtons {
        standardWindowButton(button)?.isHidden = true
      }
      level = .popUpMenu
      isMovable = false
    }

    // Клик по значку только что был — курсор над ним. Окно — под строкой
    // меню того экрана, где курсор, по центру значка, не вылезая за края.
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
        ?? NSScreen.main
    let visible = screen?.visibleFrame ?? NSRect(origin: .zero, size: size)
    let margin: CGFloat = 8
    var x = mouse.x - size.width / 2
    x = min(max(x, visible.minX + margin), visible.maxX - size.width - margin)
    let y = visible.maxY - size.height - 6
    setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
    makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  /// Вернуть окну прежний вид. [showMain] — сразу показать главное окно,
  /// [notify] — сообщить Dart, что мини-окно закрылось само.
  func exitPopover(showMain: Bool, notify: Bool) {
    guard inPopover else {
      if showMain { showMainWindow() }
      return
    }
    inPopover = false
    orderOut(nil)
    styleMask = savedStyle
    titleVisibility = savedTitleVisibility
    titlebarAppearsTransparent = savedTitlebarTransparent
    for button in Self.titleButtons {
      standardWindowButton(button)?.isHidden = false
    }
    level = savedLevel
    isMovable = savedMovable
    setFrame(savedFrame, display: false)

    if notify { onPopoverDismissed?() }
    if showMain {
      showMainWindow()
    } else if wasVisible {
      // Главное окно было открыто до мини-окна — возвращаем его позади
      // остальных: пользователь только что кликнул в другое место.
      orderBack(nil)
    }
  }

  /// Показать главное окно; из режима мини-окна сначала выходит.
  func showMainWindow() {
    if inPopover {
      exitPopover(showMain: true, notify: true)
      return
    }
    makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }

  func windowDidResignKey(_ notification: Notification) {
    if inPopover { exitPopover(showMain: false, notify: true) }
  }
}
