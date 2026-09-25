// Renders the app icon into an .iconset folder: `swift scripts/make-icon.swift <output.iconset>`.
// Run `make icon` rather than calling this directly: it also converts the iconset to Resources/AppIcon.icns.
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "AppIcon.iconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

/// Draws the icon at `pixels` × `pixels`, following the macOS icon grid (artwork inset ~10%, rounded square).
func render(pixels: Int) -> Data? {
    guard
        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ),
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
    else { return nil }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let size = CGFloat(pixels)
    let unit = size / 1_024

    // Rounded square with a soft drop shadow.
    let tile = NSRect(x: 100 * unit, y: 100 * unit, width: 824 * unit, height: 824 * unit)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185 * unit, yRadius: 185 * unit)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = 20 * unit
    shadow.shadowOffset = NSSize(width: 0, height: -10 * unit)
    shadow.set()
    NSColor.black.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    // Warm "wake up" gradient.
    NSGraphicsContext.saveGraphicsState()
    shape.addClip()
    NSGradient(
        starting: NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.25, alpha: 1),
        ending: NSColor(calibratedRed: 0.93, green: 0.2, blue: 0.47, alpha: 1)
    )?.draw(in: tile, angle: -60)

    // Ripples around the fingertip: the "poke".
    let tip = NSPoint(x: 700 * unit, y: 540 * unit)
    let rippleCenter = NSPoint(x: tip.x - 10 * unit, y: tip.y + 28 * unit)
    for (index, radius) in [120.0, 200.0, 280.0].enumerated() {
        let r = CGFloat(radius) * unit
        let ring = NSBezierPath(
            ovalIn: NSRect(x: rippleCenter.x - r, y: rippleCenter.y - r, width: r * 2, height: r * 2))
        ring.lineWidth = 18 * unit
        NSColor.white.withAlphaComponent(0.35 - Double(index) * 0.1).setStroke()
        ring.stroke()
    }

    // Pointing hand.
    let config = NSImage.SymbolConfiguration(pointSize: 420 * unit, weight: .semibold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let hand = NSImage(systemSymbolName: "hand.point.right.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config)
    {
        let handSize = hand.size
        let origin = NSPoint(x: tip.x - handSize.width + 30 * unit, y: tip.y - handSize.height / 2 - 20 * unit)
        let handShadow = NSShadow()
        handShadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
        handShadow.shadowBlurRadius = 16 * unit
        handShadow.shadowOffset = NSSize(width: 0, height: -8 * unit)
        handShadow.set()
        hand.draw(in: NSRect(origin: origin, size: handSize))
    }
    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.restoreGraphicsState()
    return bitmap.representation(using: .png, properties: [:])
}

for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = scale == 1 ? "icon_\(points)x\(points).png" : "icon_\(points)x\(points)@2x.png"
        guard let png = render(pixels: points * scale) else { fatalError("Could not render \(name)") }
        try png.write(to: output.appendingPathComponent(name))
    }
}
