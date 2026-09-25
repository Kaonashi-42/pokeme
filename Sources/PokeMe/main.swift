import AppKit
import SwiftUI

// `PokeMe --render-preview <file.png>` renders the overlay with the sample meeting to an image and exits.
// Used by `make screenshot` for the README; run the unsandboxed `swift run` build so it can write anywhere.
if let flag = CommandLine.arguments.firstIndex(of: "--render-preview"), CommandLine.arguments.count > flag + 1 {
    let output = URL(fileURLWithPath: CommandLine.arguments[flag + 1])
    let view = OverlayView(
        meeting: .preview, color: Color(nsColor: .systemPink), onJoin: { _ in }, onSnooze: {}, onDismiss: {}
    )
    .frame(width: 1_440, height: 900)
    let renderer = ImageRenderer(content: view)
    guard
        let image = renderer.cgImage,
        let png = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else {
        FileHandle.standardError.write(Data("Could not render the overlay\n".utf8))
        exit(1)
    }
    try png.write(to: output)
    exit(0)
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(.accessory)  // Menu bar only: no Dock icon, no app menu.
NSApplication.shared.run()
