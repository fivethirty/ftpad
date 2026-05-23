import AppKit

@MainActor
class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let onToggle: () -> Void
    private let onShow: () -> Void

    init(onToggle: @escaping () -> Void, onShow: @escaping () -> Void) {
        self.onToggle = onToggle
        self.onShow = onShow
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        guard let button = statusItem.button else { return }
        let image = StatusBarController.tildeImage()
        statusItem.length = image.size.width - 6
        button.image = image
        button.target = self
        button.action = #selector(handleClick(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            let open = menu.addItem(
                withTitle: "Open ftpad",
                action: #selector(handleOpen),
                keyEquivalent: " "
            )
            open.keyEquivalentModifierMask = [.control, .shift]
            open.target = self
            menu.addItem(.separator())
            let about = menu.addItem(withTitle: "ftpad \(buildSHA)", action: nil, keyEquivalent: "")
            about.isEnabled = false
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
            statusItem.menu = menu
            sender.performClick(nil)
            statusItem.menu = nil
        } else {
            onToggle()
        }
    }

    @objc private func handleOpen() {
        onShow()
    }

    private static func tildeImage() -> NSImage {
        let font = NSFont.monospacedSystemFont(ofSize: 16, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let str = "[~]" as NSString
        let size = str.size(withAttributes: attrs)
        let image = NSImage(size: size, flipped: false) { _ in
            str.draw(at: .zero, withAttributes: attrs)
            return true
        }
        image.isTemplate = true
        return image
    }
}
