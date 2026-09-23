import Foundation

/// User-facing strings. Locale and time zone are injectable so tests are deterministic.
public enum Format {
    /// "Starts in 1:05", "Starting now" or "Started 2:30 ago".
    public static func countdown(to start: Date, now: Date) -> String {
        let seconds = Int(start.timeIntervalSince(now))
        if seconds > 0 { return "Starts in \(clock(seconds))" }
        if seconds > -10 { return "Starting now" }
        return "Started \(clock(-seconds)) ago"
    }

    /// Menu bar label for the next meeting: "Standup in 12m", or "Standup at 14:30" when an hour or more away.
    public static func statusTitle(
        for meeting: Meeting?,
        now: Date,
        maxTitleLength: Int = 20,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        guard let meeting else { return "" }
        let minutes = max(1, Int((meeting.start.timeIntervalSince(now) / 60).rounded(.up)))
        let when = minutes < 60 ? "in \(minutes)m" : "at \(time(meeting.start, locale: locale, timeZone: timeZone))"
        return "\(truncated(meeting.title, to: maxTitleLength)) \(when)"
    }

    /// "14:00 – 14:30" (or "2:00 PM – 2:30 PM", depending on locale).
    public static func timeRange(
        _ start: Date,
        _ end: Date,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        "\(time(start, locale: locale, timeZone: timeZone)) – \(time(end, locale: locale, timeZone: timeZone))"
    }

    /// Short time of day in the given locale.
    public static func time(
        _ date: Date,
        locale: Locale = .autoupdatingCurrent,
        timeZone: TimeZone = .autoupdatingCurrent
    ) -> String {
        date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, locale: locale, timeZone: timeZone))
    }

    /// `text` cut to `limit` characters, ending with an ellipsis when shortened.
    public static func truncated(_ text: String, to limit: Int) -> String {
        text.count <= limit ? text : text.prefix(max(0, limit - 1)) + "…"
    }

    private static func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
