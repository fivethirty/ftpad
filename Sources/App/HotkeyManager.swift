import Carbon.HIToolbox
import ftpadCore

class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private let handler: @Sendable () -> Void

    init(config: Config, handler: @Sendable @escaping () -> Void) {
        self.handler = handler
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
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let ptr = userData else { return noErr }
                let handler = Unmanaged<HotkeyManager>.fromOpaque(ptr).takeUnretainedValue().handler
                DispatchQueue.main.async { handler() }
                return noErr
            },
            1, &eventSpec, selfPtr, nil
        )
    }
}
