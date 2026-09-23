import Foundation

/// User preferences, persisted in `UserDefaults`.
public struct Settings: @unchecked Sendable {  // UserDefaults is thread-safe.
    /// Choices offered for "poke me N minutes before".
    public static let leadMinuteOptions = [0, 1, 2, 5]

    private enum Key {
        static let leadMinutes = "lead"
        static let disabledCalendars = "disabledCalendars"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [Key.leadMinutes: 1])
    }

    /// Minutes before a meeting starts to show the overlay.
    public var leadMinutes: Int {
        get { defaults.integer(forKey: Key.leadMinutes) }
        nonmutating set { defaults.set(max(0, newValue), forKey: Key.leadMinutes) }
    }

    /// Calendars the user opted out of. Stored as an opt-out list so newly added calendars are watched by default.
    public var disabledCalendarIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: Key.disabledCalendars) ?? []) }
        nonmutating set { defaults.set(newValue.sorted(), forKey: Key.disabledCalendars) }
    }

    public func isCalendarEnabled(_ id: String) -> Bool {
        !disabledCalendarIDs.contains(id)
    }

    public func setCalendar(_ id: String, enabled: Bool) {
        if enabled {
            disabledCalendarIDs.remove(id)
        } else {
            disabledCalendarIDs.insert(id)
        }
    }
}
