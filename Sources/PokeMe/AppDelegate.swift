import AppKit
import PokeMeCore
import os

extension Logger {
    static let app = Logger(subsystem: "com.pokeme.app", category: "app")
}

/// Wires the calendar, the scheduler, the menu bar item and the overlay together.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let pollInterval: TimeInterval = 10
    private static let snoozeDuration: Duration = .seconds(60)
    /// Look slightly into the past so a meeting that just started (e.g. after wake) can still fire.
    private static let lookBack: TimeInterval = 120

    private let settings = Settings()
    private let calendar = CalendarService()
    private let overlay = OverlayController()
    private var scheduler = AlertScheduler(leadTime: 0)
    private var statusMenu: StatusMenuController?
    private var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenu = StatusMenuController(
            calendar: calendar,
            settings: settings,
            upcomingMeetings: { [unowned self] in upcomingMeetings(at: .now).filter { $0.end > .now } },
            onShow: { [unowned self] in present($0) },
            onChange: { [unowned self] in tick() }
        )
        calendar.onChange = { [unowned self] in tick() }
        calendar.requestAccess()

        let timer = Timer(timeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 2
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        tick()
    }

    /// Alertable meetings from a little before `now` until midnight, soonest first.
    private func upcomingMeetings(at now: Date) -> [Meeting] {
        let startOfDay = Calendar.current.startOfDay(for: now)
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? now.addingTimeInterval(86_400)
        let meetings = calendar.meetings(
            from: now.addingTimeInterval(-Self.lookBack),
            to: midnight,
            excluding: settings.disabledCalendarIDs
        )
        return Meeting.alertable(meetings)
    }

    private func tick() {
        let now = Date.now
        let meetings = upcomingMeetings(at: now)
        scheduler.leadTime = TimeInterval(settings.leadMinutes * 60)
        // One overlay at a time: back-to-back meetings wait until the current one is dismissed.
        if !overlay.isVisible, let meeting = scheduler.nextAlert(in: meetings, at: now) {
            present(meeting)
        }
        statusMenu?.setTitle(Format.statusTitle(for: meetings.first { $0.start > now }, now: now))
    }

    private func present(_ meeting: Meeting) {
        Logger.app.info("Poking for meeting starting at \(meeting.start, privacy: .public)")
        overlay.present(meeting, color: calendar.color(forCalendarID: meeting.calendarID)) { [weak self] in
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: Self.snoozeDuration)
                self?.present(meeting)
            }
        }
    }
}
