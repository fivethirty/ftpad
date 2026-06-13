import AppKit
import ftpadCore
import ServiceManagement

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var padWindow: PadWindow?
    private var statusBar: StatusBarController?
    private var hotkey: HotkeyManager?
    private var configWatcher: DispatchSourceFileSystemObject?

    func applicationDidFinishLaunching(_: Notification) {
        setupMainMenu()

        let config = Config.load()

        padWindow = PadWindow(config: config)
        statusBar = StatusBarController(
            onToggle: { [weak self] in self?.padWindow?.toggle() },
            onShow: { [weak self] in self?.padWindow?.show() }
        )
        hotkey = HotkeyManager(config: config) { [weak self] in
            Task { @MainActor in self?.padWindow?.toggle() }
        }

        try? SMAppService.mainApp.register()
        watchConfig()
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)

        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu

        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = mainMenu
    }

    private func watchConfig() {
        let dir = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ftpad")

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fileDescriptor = open(dir.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let config = Config.load()
            padWindow?.apply(config: config)
            hotkey?.update(config: config)
        }

        source.setCancelHandler { close(fileDescriptor) }
        source.resume()
        configWatcher = source
    }
}
