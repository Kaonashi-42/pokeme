import AppKit
import PokeMeCore
import ServiceManagement
import os

/// The menu bar item: next-meeting label plus a menu rebuilt each time it opens.
@MainActor
final class StatusMenuController: NSObject, NSMenuDelegate {
    private static let calendarPrivacyURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
    )

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let calendar: CalendarService
    private let settings: Settings
    private let upcomingMeetings: () -> [Meeting]
    private let onShow: (Meeting) -> Void
    private let onChange: () -> Void

    init(
        calendar: CalendarService,
        settings: Settings,
        upcomingMeetings: @escaping () -> [Meeting],
        onShow: @escaping (Meeting) -> Void,
        onChange: @escaping () -> Void
    ) {
        self.calendar = calendar
        self.settings = settings
        self.upcomingMeetings = upcomingMeetings
        self.onShow = onShow
        self.onChange = onChange
        super.init()
        statusItem.button?.image = NSImage(
            systemSymbolName: "hand.point.right.fill",
            accessibilityDescription: "PokeMe"
        )
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
    }

    /// The menu bar shows only the icon to save space; the next meeting is available on hover.
    func setNextMeeting(_ description: String) {
        statusItem.button?.toolTip = description.isEmpty ? "PokeMe: no more meetings today" : "Next: \(description)"
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        if calendar.isAuthorized {
            addMeetings(to: menu)
        } else {
            menu.addItem(
                ActionMenuItem("Grant Calendar Access…") {
                    if let url = Self.calendarPrivacyURL { NSWorkspace.shared.open(url) }
                }
            )
        }
        menu.addItem(.separator())
        menu.addItem(submenu("Poke Me", leadTimeMenu()))
        if calendar.isAuthorized {
            menu.addItem(submenu("Calendars", calendarsMenu()))
        }
        menu.addItem(ActionMenuItem("Preview Overlay") { [onShow] in onShow(.preview) })
        menu.addItem(
            ActionMenuItem("Launch at Login", checked: SMAppService.mainApp.status == .enabled) {
                Self.toggleLaunchAtLogin()
            }
        )
        menu.addItem(.separator())
        menu.addItem(ActionMenuItem("Quit PokeMe") { NSApp.terminate(nil) })
    }

    private func addMeetings(to menu: NSMenu) {
        let meetings = upcomingMeetings()
        if meetings.isEmpty {
            menu.addItem(withTitle: "No more meetings today", action: nil, keyEquivalent: "")
        }
        for meeting in meetings {
            menu.addItem(
                ActionMenuItem("\(Format.time(meeting.start))   \(meeting.title)") { [onShow] in onShow(meeting) })
        }
    }

    private func leadTimeMenu() -> NSMenu {
        let menu = NSMenu()
        for minutes in Settings.leadMinuteOptions {
            let title = minutes == 0 ? "When it starts" : "\(minutes) min before"
            menu.addItem(
                ActionMenuItem(title, checked: settings.leadMinutes == minutes) { [settings, onChange] in
                    settings.leadMinutes = minutes
                    onChange()
                }
            )
        }
        return menu
    }

    private func calendarsMenu() -> NSMenu {
        let menu = NSMenu()
        for group in calendar.calendarsBySource {
            menu.addItem(withTitle: group.source, action: nil, keyEquivalent: "")
            for cal in group.calendars {
                menu.addItem(calendarToggle(id: cal.calendarIdentifier, title: cal.title, color: cal.color))
            }
        }
        return menu
    }

    /// A checkbox hosted in a custom view: clicking it keeps the menu open so several calendars can be toggled.
    private func calendarToggle(id: String, title: String, color: NSColor?) -> NSMenuItem {
        let label = NSMutableAttributedString(string: "● ", attributes: [.foregroundColor: color ?? .systemGray])
        label.append(NSAttributedString(string: title, attributes: [.foregroundColor: NSColor.labelColor]))
        let box = NSButton(checkboxWithTitle: "", target: self, action: #selector(toggleCalendar(_:)))
        box.attributedTitle = label
        box.identifier = NSUserInterfaceItemIdentifier(id)
        box.state = settings.isCalendarEnabled(id) ? .on : .off
        box.sizeToFit()
        box.setFrameOrigin(NSPoint(x: 24, y: 3))
        let row = NSView(frame: NSRect(x: 0, y: 0, width: box.frame.width + 40, height: box.frame.height + 6))
        row.addSubview(box)
        let item = NSMenuItem()
        item.view = row
        return item
    }

    @objc private func toggleCalendar(_ box: NSButton) {
        guard let id = box.identifier?.rawValue else { return }
        settings.setCalendar(id, enabled: box.state == .on)
        onChange()
    }

    private func submenu(_ title: String, _ menu: NSMenu) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    private static func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            Logger.app.error("Launch at login toggle failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// An `NSMenuItem` that runs a closure, avoiding a selector per action.
private final class ActionMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(_ title: String, checked: Bool = false, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(title: title, action: #selector(fire), keyEquivalent: "")
        target = self
        state = checked ? .on : .off
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func fire() {
        handler()
    }
}

extension Meeting {
    /// A fake meeting starting in a minute, for "Preview Overlay".
    static var preview: Meeting {
        Meeting(
            id: "preview-\(UUID().uuidString)",
            title: "Weekly design review",
            start: .now.addingTimeInterval(60),
            end: .now.addingTimeInterval(1_860),
            location: "Room 4",
            joinURL: URL(string: "https://meet.google.com/abc-defg-hij"),
            calendarTitle: "Work",
            attendeeCount: 6
        )
    }
}
