#!/usr/bin/swift
// Renders Resources/AppIcon.png — a "6 7" meme themed app icon.
// Run with: swift Scripts/make-icon.swift

import AppKit

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

guard let ctx = NSGraphicsContext.current?.cgContext else {
    fatalError("no graphics context")
}

let rect = CGRect(origin: .zero, size: size)
let cornerRadius: CGFloat = size.width * 0.22
NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius).addClip()

let colors = [
    NSColor(calibratedRed: 0.42, green: 0.20, blue: 0.95, alpha: 1).cgColor,
    NSColor(calibratedRed: 0.98, green: 0.22, blue: 0.50, alpha: 1).cgColor,
]
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: size.width, y: 0), options: [])

let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
shadow.shadowBlurRadius = 30
shadow.shadowOffset = NSSize(width: 0, height: -14)

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center

let numberFont = NSFont.systemFont(ofSize: 520, weight: .black)
let numberAttrs: [NSAttributedString.Key: Any] = [
    .font: numberFont,
    .foregroundColor: NSColor.white,
    .paragraphStyle: paragraph,
    .shadow: shadow,
]
let numberString = NSAttributedString(string: "67", attributes: numberAttrs)
let numberSize = numberString.size()
numberString.draw(at: CGPoint(x: (size.width - numberSize.width) / 2, y: (size.height - numberSize.height) / 2 - 30))

let emojiFont = NSFont.systemFont(ofSize: 170)
let emojiAttrs: [NSAttributedString.Key: Any] = [.font: emojiFont]

let leftHand = NSAttributedString(string: "🤚", attributes: emojiAttrs)
leftHand.draw(at: CGPoint(x: 50, y: size.height - 260))

let rightHand = NSAttributedString(string: "🖐️", attributes: emojiAttrs)
let rightSize = rightHand.size()
rightHand.draw(at: CGPoint(x: size.width - rightSize.width - 50, y: 90))

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
    let rep = NSBitmapImageRep(data: tiff),
    let png = rep.representation(using: .png, properties: [:])
else {
    fatalError("failed to render PNG")
}

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/AppIcon.png"
let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
try png.write(to: outputURL)
print("wrote \(outputPath)")
