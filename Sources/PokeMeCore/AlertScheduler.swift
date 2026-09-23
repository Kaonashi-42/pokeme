import Foundation

/// Decides which meeting deserves a full-screen poke, making sure each occurrence fires only once.
public struct AlertScheduler: Sendable {
    /// How long before the start the alert fires. Zero means exactly at start time.
    public var leadTime: TimeInterval
    /// How long after the start a missed alert still fires (e.g. the Mac just woke up from sleep).
    public var gracePeriod: TimeInterval
    /// Fired meeting IDs with their start date, so old entries can be pruned.
    private var fired: [String: Date] = [:]

    public init(leadTime: TimeInterval, gracePeriod: TimeInterval = 60) {
        self.leadTime = leadTime
        self.gracePeriod = gracePeriod
    }

    /// Whether `meeting` is inside its alert window at `now`, regardless of whether it already fired.
    public func isDue(_ meeting: Meeting, at now: Date) -> Bool {
        now >= meeting.start.addingTimeInterval(-leadTime) && now < meeting.start.addingTimeInterval(gracePeriod)
    }

    /// The earliest due meeting that has not fired yet, recorded as fired. Nil when nothing is due.
    public mutating func nextAlert(in meetings: [Meeting], at now: Date) -> Meeting? {
        fired = fired.filter { $0.value > now.addingTimeInterval(-86_400) }
        guard let meeting = Meeting.alertable(meetings).first(where: { fired[$0.id] == nil && isDue($0, at: now) })
        else { return nil }
        fired[meeting.id] = meeting.start
        return meeting
    }
}
