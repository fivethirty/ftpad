import Carbon.HIToolbox
import ftpadCore

class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    @MainActor private static var currentHandler: (@Sendable () -> Void)?

    init(config: Config, handler: @Sendable @escaping () -> Void) {
        MainActor.assumeIsolated { HotkeyManager.currentHandler = handler }
        installEventHandler()
        register(config: config)
    }

    func update(config: Config) {
        unregister()
        register(config: config)
    }

    private func register(config: Config) {
        let shortcut = config.resolvedShortcut
        let hotKeyID = EventHotKeyID(signature: OSType(0x6674_7064), id: 1)
        RegisterEventHotKey(
            shortcut.keyCode, shortcut.modifiers,
            hotKeyID, GetApplicationEventTarget(),
            0, &hotKeyRef
        )
    }

    private func unregister() {
        guard let ref = hotKeyRef else { return }
        UnregisterEventHotKey(ref)
        hotKeyRef = nil
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, _ -> OSStatus in
                DispatchQueue.main.async {
                    HotkeyManager.currentHandler?()
                }
                return noErr
            },
            1, &eventSpec, nil, nil
        )
    }
}
