#!/usr/bin/env swift
import AppKit
import Foundation

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let output = resources.appendingPathComponent("AppIcon.icns")
let fileManager = FileManager.default

try fileManager.createDirectory(at: resources, withIntermediateDirectories: true)
try? fileManager.removeItem(at: iconset)
try fileManager.createDirectory(at: iconset, withIntermediateDirectories: true)

let variants: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

func writeIcon(size: Int, name: String) throws {
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let image = NSImage(size: rect.size)
    image.lockFocus()

    let corner = CGFloat(size) * 0.22
    let body = NSBezierPath(roundedRect: rect.insetBy(dx: CGFloat(size) * 0.06, dy: CGFloat(size) * 0.06), xRadius: corner, yRadius: corner)
    NSGradient(colors: [
        NSColor(calibratedRed: 0.20, green: 0.46, blue: 0.95, alpha: 1),
        NSColor(calibratedRed: 0.58, green: 0.33, blue: 0.90, alpha: 1)
    ])?.draw(in: body, angle: 135)

    NSColor.white.withAlphaComponent(0.20).setStroke()
    body.lineWidth = max(1, CGFloat(size) * 0.012)
    body.stroke()

    let graphRect = rect.insetBy(dx: CGFloat(size) * 0.20, dy: CGFloat(size) * 0.24)
    let baseline = graphRect.minY + graphRect.height * 0.42
    let path = NSBezierPath()
    path.move(to: NSPoint(x: graphRect.minX, y: baseline))
    path.curve(
        to: NSPoint(x: graphRect.minX + graphRect.width * 0.34, y: graphRect.minY + graphRect.height * 0.74),
        controlPoint1: NSPoint(x: graphRect.minX + graphRect.width * 0.10, y: baseline),
        controlPoint2: NSPoint(x: graphRect.minX + graphRect.width * 0.18, y: graphRect.maxY)
    )
    path.curve(
        to: NSPoint(x: graphRect.minX + graphRect.width * 0.66, y: graphRect.minY + graphRect.height * 0.36),
        controlPoint1: NSPoint(x: graphRect.minX + graphRect.width * 0.46, y: graphRect.minY + graphRect.height * 0.44),
        controlPoint2: NSPoint(x: graphRect.minX + graphRect.width * 0.54, y: graphRect.minY + graphRect.height * 0.20)
    )
    path.curve(
        to: NSPoint(x: graphRect.maxX, y: graphRect.minY + graphRect.height * 0.60),
        controlPoint1: NSPoint(x: graphRect.minX + graphRect.width * 0.76, y: graphRect.minY + graphRect.height * 0.58),
        controlPoint2: NSPoint(x: graphRect.minX + graphRect.width * 0.86, y: graphRect.minY + graphRect.height * 0.68)
    )

    NSColor.white.setStroke()
    path.lineCapStyle = .round
    path.lineJoinStyle = .round
    path.lineWidth = max(2, CGFloat(size) * 0.070)
    path.stroke()

    NSColor.white.withAlphaComponent(0.96).setFill()
    for point in [
        NSPoint(x: graphRect.minX + graphRect.width * 0.34, y: graphRect.minY + graphRect.height * 0.74),
        NSPoint(x: graphRect.minX + graphRect.width * 0.66, y: graphRect.minY + graphRect.height * 0.36),
        NSPoint(x: graphRect.maxX, y: graphRect.minY + graphRect.height * 0.60)
    ] {
        let radius = max(2, CGFloat(size) * 0.035)
        NSBezierPath(ovalIn: NSRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)).fill()
    }

    image.unlockFocus()

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        throw NSError(domain: "AppIcon", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to render icon \(name)"])
    }
    try png.write(to: iconset.appendingPathComponent(name))
}

for variant in variants {
    try writeIcon(size: variant.0, name: variant.1)
}

try? fileManager.removeItem(at: output)
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else {
    throw NSError(domain: "AppIcon", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: "iconutil failed"])
}

print(output.path)
