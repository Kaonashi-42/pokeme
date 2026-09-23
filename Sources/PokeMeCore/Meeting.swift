import Foundation

/// A calendar event reduced to what PokeMe needs, decoupled from EventKit so the logic stays testable.
public struct Meeting: Equatable, Identifiable, Sendable {
    /// Unique per occurrence: recurring events share an event identifier, so the start date is part of it.
    public let id: String
    public let title: String
    public let start: Date
    public let end: Date
    public let location: String?
    public let joinURL: URL?
    public let calendarID: String?
    public let calendarTitle: String?
    public let attendeeCount: Int
    public let isAllDay: Bool
    public let isDeclined: Bool

    public init(
        id: String,
        title: String,
        start: Date,
        end: Date,
        location: String? = nil,
        joinURL: URL? = nil,
        calendarID: String? = nil,
        calendarTitle: String? = nil,
        attendeeCount: Int = 0,
        isAllDay: Bool = false,
        isDeclined: Bool = false
    ) {
        self.id = id
        self.title = title
        self.start = start
        self.end = end
        self.location = location
        self.joinURL = joinURL
        self.calendarID = calendarID
        self.calendarTitle = calendarTitle
        self.attendeeCount = attendeeCount
        self.isAllDay = isAllDay
        self.isDeclined = isDeclined
    }

    /// The location worth showing, or nil when it is empty or just the video link.
    public var displayLocation: String? {
        guard let location, !location.isEmpty, !location.contains("://") else { return nil }
        return location
    }

    /// Meetings worth poking about (timed and not declined), soonest first.
    public static func alertable(_ meetings: [Meeting]) -> [Meeting] {
        meetings
            .filter { !$0.isAllDay && !$0.isDeclined }
            .sorted { $0.start < $1.start }
    }
}
