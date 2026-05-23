import AppKit
import ftpadCore

@MainActor
class PadWindow: NSObject, NSWindowDelegate {
    private let window: NSWindow
    private let textView: NSTextView
    private var localMonitor: Any?

    init(config: Config) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: config.width ?? 700, height: config.height ?? 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        let scrollView = NSScrollView(frame: window.contentView!.bounds)
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsetsZero

        textView = NSTextView(frame: scrollView.bounds)
        textView.autoresizingMask = [.width, .height]
        textView.font = config.resolvedFont
        textView.backgroundColor = config.resolvedBackgroundColor
        textView.textColor = config.resolvedTextColor
        textView.insertionPointColor = .white
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.textContainer?.lineFragmentPadding = 0
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(white: 1.0, alpha: 0.15),
            .foregroundColor: config.resolvedTextColor,
        ]
        textView.string = UserDefaults.standard.string(forKey: "ftpad-content") ?? ""

        scrollView.documentView = textView

        super.init()

        window.title = ""
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = false
        window.isMovable = false
        window.setFrameAutosaveName("")
        window.center()
        window.delegate = self
        window.backgroundColor = config.resolvedBackgroundColor
        window.contentView?.addSubview(scrollView)

        for btn in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
            window.standardWindowButton(btn)?.isHidden = true
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.hide()
                return nil
            }
            return event
        }
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeFirstResponder(textView)
    }

    func hide() {
        window.orderOut(nil)
    }

    func toggle() {
        window.isVisible ? hide() : show()
    }

    func apply(config: Config) {
        textView.font = config.resolvedFont
        textView.backgroundColor = config.resolvedBackgroundColor
        textView.textColor = config.resolvedTextColor
        textView.insertionPointColor = .white
        window.backgroundColor = config.resolvedBackgroundColor
    }

    @objc private func textDidChange() {
        UserDefaults.standard.set(textView.string, forKey: "ftpad-content")
    }

    func windowDidResignKey(_: Notification) { hide() }
    func windowShouldClose(_: NSWindow) -> Bool { hide(); return false }
}
