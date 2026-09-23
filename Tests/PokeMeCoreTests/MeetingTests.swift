import Foundation
import Testing

@testable import PokeMeCore

struct MeetingTests {
    @Test func alertableDropsAllDayAndDeclinedAndSortsByStart() {
        let meetings: [Meeting] = [
            .fixture(id: "late", startsIn: 600),
            .fixture(id: "allDay", startsIn: 0, isAllDay: true),
            .fixture(id: "early", startsIn: 60),
            .fixture(id: "declined", startsIn: 30, isDeclined: true),
        ]
        #expect(Meeting.alertable(meetings).map(\.id) == ["early", "late"])
    }

    @Test(
        arguments: [
            ("Room 4", "Room 4"),
            ("https://zoom.us/j/1", nil),
            ("", nil),
        ] as [(String, String?)])
    func displayLocation(location: String, expected: String?) {
        #expect(Meeting.fixture(startsIn: 0, location: location).displayLocation == expected)
    }

    @Test func displayLocationIsNilWithoutLocation() {
        #expect(Meeting.fixture(startsIn: 0).displayLocation == nil)
    }
}
