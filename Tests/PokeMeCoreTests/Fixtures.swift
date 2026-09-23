import Foundation

@testable import PokeMeCore

/// Fixed reference time so tests never depend on the clock.
let t0 = Date(timeIntervalSince1970: 1_800_000_000)

extension Meeting {
    static func fixture(
        id: String = UUID().uuidString,
        title: String = "Standup",
        startsIn offset: TimeInterval,
        duration: TimeInterval = 1_800,
        location: String? = nil,
        isAllDay: Bool = false,
        isDeclined: Bool = false,
        isCanceled: Bool = false
    ) -> Meeting {
        Meeting(
            id: id,
            title: title,
            start: t0.addingTimeInterval(offset),
            end: t0.addingTimeInterval(offset + duration),
            location: location,
            isAllDay: isAllDay,
            isDeclined: isDeclined,
            isCanceled: isCanceled
        )
    }
}
