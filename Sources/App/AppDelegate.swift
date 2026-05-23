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

    private func watchConfig() {
        let dir = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ftpad")

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fd = open(dir.path, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self else { return }
            let config = Config.load()
            padWindow?.apply(config: config)
            hotkey?.update(config: config)
        }

        source.setCancelHandler { close(fd) }
        source.resume()
        configWatcher = source
    }
}
