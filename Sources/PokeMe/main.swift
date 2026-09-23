import AppKit

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.setActivationPolicy(.accessory)  // Menu bar only: no Dock icon, no app menu.
NSApplication.shared.run()
