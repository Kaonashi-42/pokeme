import AppKit
import EventKit
import PokeMeCore
import os

/// Thin EventKit wrapper: permission, calendars, and events mapped to `Meeting`.
@MainActor
final class CalendarService {
    private let store = EKEventStore()
    /// Called on the main actor when access is granted or the calendar database changes.
    var onChange: (() -> Void)?

    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// Event calendars grouped by account ("iCloud", "Google"…), both sorted by name.
    var calendarsBySource: [(source: String, calendars: [EKCalendar])] {
        Dictionary(grouping: store.calendars(for: .event)) { $0.source.title }
            .map { (source: $0.key, calendars: $0.value.sorted { $0.title < $1.title }) }
            .sorted { $0.source < $1.source }
    }

    init() {
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) {
            [weak self] _ in
            MainActor.assumeIsolated { self?.onChange?() }
        }
    }

    func requestAccess() {
        store.requestFullAccessToEvents { [weak self] granted, error in
            if let error {
                Logger.app.error("Calendar access request failed: \(error.localizedDescription, privacy: .public)")
            }
            Logger.app.info("Calendar access granted: \(granted)")
            Task { @MainActor in self?.onChange?() }
        }
    }

    func meetings(from start: Date, to end: Date, excluding disabledIDs: Set<String>) -> [Meeting] {
        guard isAuthorized else { return [] }
        let calendars = store.calendars(for: .event).filter { !disabledIDs.contains($0.calendarIdentifier) }
        // An empty list would mean "all calendars" to EventKit, the opposite of what the user asked for.
        guard !calendars.isEmpty else { return [] }
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return store.events(matching: predicate).map(Meeting.init(event:))
    }

    func color(forCalendarID id: String?) -> NSColor {
        id.flatMap(store.calendar(withIdentifier:))?.color ?? .systemPink
    }
}

extension Meeting {
    init(event: EKEvent) {
        let baseID = event.eventIdentifier ?? event.calendarItemIdentifier
        self.init(
            id: "\(baseID)@\(event.startDate.timeIntervalSince1970)",
            title: event.title ?? "Untitled meeting",
            start: event.startDate,
            end: event.endDate,
            location: event.location,
            joinURL: MeetingLink.find(in: [event.url?.absoluteString, event.location, event.notes]),
            calendarID: event.calendar?.calendarIdentifier,
            calendarTitle: event.calendar?.title,
            attendeeCount: event.attendees?.count ?? 0,
            isAllDay: event.isAllDay,
            isDeclined: event.attendees?.first { $0.isCurrentUser }?.participantStatus == .declined
        )
    }
}
