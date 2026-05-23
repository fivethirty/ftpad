#!/usr/bin/env swift
import AppKit

let iconsetDir = "ftpad.iconset"
try? FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

let specs: [(name: String, size: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func makeIcon(size: Int) -> NSImage {
    NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
        let radius = CGFloat(size) * 0.2
        let bg = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
        NSColor(red: 0.118, green: 0.118, blue: 0.118, alpha: 1).setFill()
        bg.fill()

        let font = NSFont.monospacedSystemFont(ofSize: CGFloat(size) * 0.35, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor(red: 0.831, green: 0.831, blue: 0.831, alpha: 1),
        ]
        let str = "[~]" as NSString
        let strSize = str.size(withAttributes: attrs)
        str.draw(at: NSPoint(
            x: (rect.width - strSize.width) / 2,
            y: (rect.height - strSize.height) / 2
        ), withAttributes: attrs)
        return true
    }
}

for spec in specs {
    let image = makeIcon(size: spec.size)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:])
    else { continue }
    try! png.write(to: URL(fileURLWithPath: "\(iconsetDir)/\(spec.name).png"))
}

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir, "-o", "ftpad.icns"]
try! task.run()
task.waitUntilExit()

print("Generated ftpad.icns")
