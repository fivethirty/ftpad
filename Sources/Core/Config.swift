import AppKit
import Carbon.HIToolbox

public struct Config: Codable, Sendable {
    public var font: String?
    public var fontSize: CGFloat?
    public var backgroundColor: String?
    public var textColor: String?
    public var lightScrollbar: Bool?
    public var shortcut: String?
    public var width: CGFloat?
    public var height: CGFloat?

    public static let defaults = Config(
        font: nil,
        fontSize: 14,
        backgroundColor: "#1e1e1e",
        textColor: "#d4d4d4",
        lightScrollbar: true,
        shortcut: "ctrl+shift+space",
        width: 700,
        height: 500
    )

    public var resolvedScrollerKnobStyle: NSScroller.KnobStyle {
        (lightScrollbar ?? true) ? .light : .dark
    }

    public static func load() -> Config {
        let path = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ftpad/config.json")
        guard let data = try? Data(contentsOf: path) else { return Config() }
        return load(from: data)
    }

    public static func load(from data: Data) -> Config {
        (try? JSONDecoder().decode(Config.self, from: data)) ?? Config()
    }

    public var resolvedFont: NSFont {
        let size = fontSize ?? Config.defaults.fontSize!
        guard let name = font else {
            return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
        return NSFont(name: name, size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }

    public var resolvedBackgroundColor: NSColor {
        colorFromHex(backgroundColor ?? Config.defaults.backgroundColor!)
            ?? NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1)
    }

    public var resolvedTextColor: NSColor {
        colorFromHex(textColor ?? Config.defaults.textColor!)
            ?? NSColor(red: 0.831, green: 0.831, blue: 0.831, alpha: 1)
    }

    public var resolvedShortcut: (keyCode: UInt32, modifiers: UInt32) {
        let parts = (shortcut ?? Config.defaults.shortcut!)
            .lowercased()
            .split(separator: "+")
            .map(String.init)

        var modifiers: UInt32 = 0
        var keyCode = UInt32(kVK_Space)

        for part in parts {
            switch part {
            case "ctrl": modifiers |= UInt32(controlKey)
            case "shift": modifiers |= UInt32(shiftKey)
            case "cmd": modifiers |= UInt32(cmdKey)
            case "opt": modifiers |= UInt32(optionKey)
            case "space": keyCode = UInt32(kVK_Space)
            default:
                if let code = keyCodeForCharacter(part) { keyCode = code }
            }
        }

        return (keyCode, modifiers)
    }
}

private func colorFromHex(_ hex: String) -> NSColor? {
    let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard hex.count == 6, let value = UInt64(hex, radix: 16) else { return nil }
    return NSColor(
        red: CGFloat((value >> 16) & 0xFF) / 255,
        green: CGFloat((value >> 8) & 0xFF) / 255,
        blue: CGFloat(value & 0xFF) / 255,
        alpha: 1
    )
}

private func keyCodeForCharacter(_ character: String) -> UInt32? {
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
          let layoutData = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
    else { return nil }

    let layout = unsafeBitCast(layoutData, to: CFData.self)
    let ptr = unsafeBitCast(CFDataGetBytePtr(layout), to: UnsafePointer<UCKeyboardLayout>.self)

    for code in 0 ..< 128 {
        var deadKeys: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        UCKeyTranslate(
            ptr, UInt16(code), UInt16(kUCKeyActionDisplay),
            0, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeys, 4, &length, &chars
        )
        if length > 0,
           String(utf16CodeUnits: chars, count: length).lowercased() == character
        {
            return UInt32(code)
        }
    }
    return nil
}
