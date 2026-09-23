import AppKit
import PokeMeCore
import SwiftUI

/// Shows the full-screen overlay on every display, above full-screen apps and on every Space.
@MainActor
final class OverlayController {
    private var windows: [NSWindow] = []
    /// Called after the user closes the overlay (join, snooze or dismiss).
    var onDismiss: (() -> Void)?

    var isVisible: Bool { !windows.isEmpty }

    func present(_ meeting: Meeting, color: NSColor, onSnooze: @escaping () -> Void) {
        closeWindows()
        NSSound(named: "Glass")?.play()
        NSApp.activate(ignoringOtherApps: true)
        let view = OverlayView(
            meeting: meeting,
            color: Color(nsColor: color),
            onJoin: { [weak self] url in
                NSWorkspace.shared.open(url)
                self?.dismiss()
            },
            onSnooze: { [weak self] in
                onSnooze()
                self?.dismiss()
            },
            onDismiss: { [weak self] in self?.dismiss() }
        )
        windows = NSScreen.screens.map { makeWindow(on: $0, view: view) }
        // NSScreen.screens[0] is the display with the menu bar: give it keyboard focus for Return / Esc.
        windows.first?.makeKey()
    }

    func dismiss() {
        guard isVisible else { return }
        closeWindows()
        // Give focus back to the app the user was in before the poke.
        NSApp.hide(nil)
        onDismiss?()
    }

    private func closeWindows() {
        for window in windows { window.orderOut(nil) }
        windows = []
    }

    private func makeWindow(on screen: NSScreen, view: OverlayView) -> NSWindow {
        let window = OverlayWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.backgroundColor = .clear
        window.contentView = NSHostingView(rootView: view)
        window.setFrame(screen.frame, display: true)
        window.alphaValue = 0
        window.orderFrontRegardless()
        window.animator().alphaValue = 1
        return window
    }
}

/// Borderless windows refuse key status by default, which would disable the keyboard shortcuts.
private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}
