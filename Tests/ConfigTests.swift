import Testing
import AppKit
import Carbon.HIToolbox
@testable import ftpadCore

@Suite("Config decoding")
struct ConfigTests {
    @Test func partialConfigFallsBackIndividually() throws {
        let json = #"{"fontSize": 18}"#
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        #expect(config.fontSize == 18)
        #expect(config.font == nil)
        #expect(config.resolvedFont.pointSize == 18)
        #expect(config.backgroundColor == nil)
        _ = config.resolvedBackgroundColor
    }

    @Test func resolvedColorsParseHex() throws {
        let json = ##"{"backgroundColor": "#ff8000", "textColor": "#1e1e1e"}"##
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        let bg = config.resolvedBackgroundColor
        #expect(abs(bg.redComponent - 1.0) < 0.01)
        #expect(abs(bg.greenComponent - 0.502) < 0.01)
        #expect(abs(bg.blueComponent - 0.0) < 0.01)
        let fg = config.resolvedTextColor
        #expect(abs(fg.redComponent - 0.118) < 0.01)
    }

    @Test func invalidHexFallsBackToDefault() throws {
        let json = #"{"backgroundColor": "gg0000"}"#
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        let color = config.resolvedBackgroundColor
        #expect(abs(color.redComponent - 0.118) < 0.01)
    }

    @Test func loadFromDataDecodesFields() {
        let json = #"{"fontSize": 20, "shortcut": "cmd+shift+p"}"#
        let config = Config.load(from: Data(json.utf8))
        #expect(config.fontSize == 20)
        #expect(config.shortcut == "cmd+shift+p")
    }

    @Test func loadFromInvalidDataReturnsEmpty() {
        let config = Config.load(from: Data("not json".utf8))
        #expect(config.fontSize == nil)
        #expect(config.font == nil)
    }
}

@Suite("Shortcut parsing")
struct ShortcutTests {
    @Test func defaultShortcutHasCorrectModifiers() {
        let s = Config().resolvedShortcut
        #expect(s.keyCode == 49) // kVK_Space
        #expect(s.modifiers & UInt32(controlKey) != 0)
        #expect(s.modifiers & UInt32(shiftKey) != 0)
    }

    @Test func cmdModifierParsed() throws {
        let json = #"{"shortcut": "cmd+space"}"#
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        let s = config.resolvedShortcut
        #expect(s.modifiers & UInt32(cmdKey) != 0)
        #expect(s.modifiers & UInt32(controlKey) == 0)
    }

    @Test func unknownKeyFallsBackToSpace() throws {
        let json = #"{"shortcut": "ctrl+zzznope"}"#
        let config = try JSONDecoder().decode(Config.self, from: Data(json.utf8))
        #expect(config.resolvedShortcut.keyCode == 49)
    }
}
