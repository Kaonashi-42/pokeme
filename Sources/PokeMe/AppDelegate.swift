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
    private static let snoozeDuration: TimeInterval = 60
    /// How long after its start a meeting still gets poked: covers waking from sleep and meetings that were queued
    /// behind another overlay.
    private static let gracePeriod: TimeInterval = 300
    /// Always look at least this far ahead, so meetings just after midnight still alert late in the evening.
    private static let minimumLookAhead: TimeInterval = 3_600

    private let settings = Settings()
    private let calendar = CalendarService()
    private let overlay = OverlayController()
    private var scheduler = AlertScheduler(leadTime: 0, gracePeriod: gracePeriod)
    /// Snoozed meetings and when to show them again. Handled by `tick()` so they never replace a visible overlay.
    private var snoozed: [(meeting: Meeting, until: Date)] = []
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
        // Show the next queued meeting right away instead of waiting for the next poll.
        overlay.onDismiss = { [unowned self] in tick() }
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

    /// Alertable meetings from shortly before `now` until midnight (or at least an hour ahead), soonest first.
    private func upcomingMeetings(at now: Date) -> [Meeting] {
        let startOfDay = Calendar.current.startOfDay(for: now)
        let midnight = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? now.addingTimeInterval(86_400)
        let meetings = calendar.meetings(
            from: now.addingTimeInterval(-Self.gracePeriod),
            to: max(midnight, now.addingTimeInterval(Self.minimumLookAhead)),
            excluding: settings.disabledCalendarIDs
        )
        return Meeting.alertable(meetings)
    }

    private func tick() {
        let now = Date.now
        let meetings = upcomingMeetings(at: now)
        scheduler.leadTime = TimeInterval(settings.leadMinutes * 60)
        // One overlay at a time: back-to-back meetings wait until the current one is dismissed.
        if !overlay.isVisible {
            if let index = snoozed.firstIndex(where: { $0.until <= now }) {
                present(snoozed.remove(at: index).meeting)
            } else if let meeting = scheduler.nextAlert(in: meetings, at: now) {
                present(meeting)
            }
        }
        statusMenu?.setNextMeeting(
            Format.statusTitle(for: meetings.first { $0.start > now }, now: now, maxTitleLength: 60))
    }

    private func present(_ meeting: Meeting) {
        Logger.app.info("Poking for meeting starting at \(meeting.start, privacy: .public)")
        overlay.present(meeting, color: calendar.color(forCalendarID: meeting.calendarID)) { [weak self] in
            self?.snoozed.append((meeting, Date.now.addingTimeInterval(Self.snoozeDuration)))
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(Self.snoozeDuration))
                self?.tick()
            }
        }
    }
}
