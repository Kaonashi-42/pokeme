import Foundation
import Testing

@testable import PokeMeCore

struct FormatTests {
    private let locale = Locale(identifier: "en_GB")
    private let utc = TimeZone(identifier: "UTC") ?? .gmt

    @Test(arguments: [
        (65.0, "Starts in 1:05"),
        (1.0, "Starts in 0:01"),
        (0.0, "Starting now"),
        (-9.0, "Starting now"),
        (-150.0, "Started 2:30 ago"),
    ])
    func countdown(offset: TimeInterval, expected: String) {
        #expect(Format.countdown(to: t0.addingTimeInterval(offset), now: t0) == expected)
    }

    @Test func statusTitleIsEmptyWithoutMeeting() {
        #expect(Format.statusTitle(for: nil, now: t0) == "")
    }

    @Test(arguments: [
        (1.0, "Standup in 1m"),
        (60.0, "Standup in 1m"),
        (61.0, "Standup in 2m"),
        (59 * 60.0, "Standup in 59m"),
    ])
    func statusTitleUsesRelativeMinutesWithinAnHour(offset: TimeInterval, expected: String) {
        let title = Format.statusTitle(for: .fixture(startsIn: offset), now: t0, locale: locale, timeZone: utc)
        #expect(title == expected)
    }

    @Test func statusTitleUsesClockTimeAnHourOrMoreAway() {
        // t0 is 08:00 UTC, so a meeting in 90 minutes starts at 09:30.
        let title = Format.statusTitle(for: .fixture(startsIn: 5_400), now: t0, locale: locale, timeZone: utc)
        #expect(title == "Standup at 9:30")
    }

    @Test func statusTitleTruncatesLongTitles() {
        let meeting = Meeting.fixture(title: "Quarterly business review", startsIn: 300)
        #expect(Format.statusTitle(for: meeting, now: t0, maxTitleLength: 10) == "Quarterly… in 5m")
    }

    @Test func timeRange() {
        #expect(Format.timeRange(t0, t0.addingTimeInterval(1_800), locale: locale, timeZone: utc) == "8:00 – 8:30")
    }

    @Test(arguments: [
        ("Standup", 10, "Standup"),
        ("Standup", 7, "Standup"),
        ("Standup", 5, "Stan…"),
        ("Standup", 0, "…"),
    ])
    func truncated(text: String, limit: Int, expected: String) {
        #expect(Format.truncated(text, to: limit) == expected)
    }
}
