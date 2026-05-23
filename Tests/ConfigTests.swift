import Testing
import AppKit
@testable import ftpadCore

@Suite("NSColor hex parsing")
struct ColorTests {
    @Test func validHexWithHash() {
        #expect(NSColor(hex: "#1e1e1e") != nil)
    }

    @Test func validHexWithoutHash() {
        #expect(NSColor(hex: "d4d4d4") != nil)
    }

    @Test func invalidHex() {
        #expect(NSColor(hex: "gg0000") == nil)
        #expect(NSColor(hex: "12345") == nil)
        #expect(NSColor(hex: "") == nil)
    }

    @Test func correctChannels() throws {
        let color = try #require(NSColor(hex: "#ff8000"))
        #expect(abs(color.redComponent - 1.0) < 0.01)
        #expect(abs(color.greenComponent - 0.502) < 0.01)
        #expect(abs(color.blueComponent - 0.0) < 0.01)
    }
}

@Suite("Config decoding")
struct ConfigTests {
    @Test func emptyConfigUsesDefaults() {
        let config = Config()
        #expect(config.resolvedFont.pointSize == Config.defaults.fontSize!)
    }

    @Test func partialConfigFallsBackIndividually() throws {
        let json = #"{"fontSize": 18}"#
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        #expect(config.fontSize == 18)
        #expect(config.font == nil)
        #expect(config.resolvedFont.pointSize == 18)
        #expect(config.backgroundColor == nil)
        _ = config.resolvedBackgroundColor // always returns a value, fallback guaranteed
    }

    @Test func shortcutDefaults() {
        let config = Config()
        let shortcut = config.resolvedShortcut
        #expect(shortcut.keyCode == 49) // kVK_Space
        #expect(shortcut.modifiers != 0)
    }
}
