import Foundation
import Testing

@testable import PokeMeCore

struct AlertSchedulerTests {
    @Test func firesInsideTheLeadWindow() {
        var scheduler = AlertScheduler(leadTime: 60)
        let meeting = Meeting.fixture(startsIn: 45)
        #expect(scheduler.nextAlert(in: [meeting], at: t0) == meeting)
    }

    @Test func doesNotFireBeforeTheLeadWindow() {
        var scheduler = AlertScheduler(leadTime: 60)
        #expect(scheduler.nextAlert(in: [.fixture(startsIn: 61)], at: t0) == nil)
    }

    @Test func zeroLeadTimeFiresExactlyAtStart() {
        var scheduler = AlertScheduler(leadTime: 0)
        let meeting = Meeting.fixture(startsIn: 1)
        #expect(scheduler.nextAlert(in: [meeting], at: t0) == nil)
        #expect(scheduler.nextAlert(in: [meeting], at: t0.addingTimeInterval(1)) == meeting)
    }

    @Test func firesEachOccurrenceOnlyOnce() {
        var scheduler = AlertScheduler(leadTime: 60)
        let meeting = Meeting.fixture(startsIn: 30)
        #expect(scheduler.nextAlert(in: [meeting], at: t0) == meeting)
        #expect(scheduler.nextAlert(in: [meeting], at: t0.addingTimeInterval(10)) == nil)
    }

    @Test func stillFiresWithinGracePeriodAfterStart() {
        var scheduler = AlertScheduler(leadTime: 60, gracePeriod: 60)
        let meeting = Meeting.fixture(startsIn: -59)
        #expect(scheduler.nextAlert(in: [meeting], at: t0) == meeting)
    }

    @Test func skipsMeetingsPastTheGracePeriod() {
        var scheduler = AlertScheduler(leadTime: 60, gracePeriod: 60)
        #expect(scheduler.nextAlert(in: [.fixture(startsIn: -60)], at: t0) == nil)
    }

    @Test func skipsAllDayDeclinedAndCanceledMeetings() {
        var scheduler = AlertScheduler(leadTime: 60)
        let meetings: [Meeting] = [
            .fixture(startsIn: 10, isAllDay: true),
            .fixture(startsIn: 10, isDeclined: true),
            .fixture(startsIn: 10, isCanceled: true),
        ]
        #expect(scheduler.nextAlert(in: meetings, at: t0) == nil)
    }

    @Test func queuesBackToBackMeetingsSoonestFirst() {
        var scheduler = AlertScheduler(leadTime: 120)
        let later = Meeting.fixture(id: "later", startsIn: 90)
        let sooner = Meeting.fixture(id: "sooner", startsIn: 30)
        #expect(scheduler.nextAlert(in: [later, sooner], at: t0)?.id == "sooner")
        #expect(scheduler.nextAlert(in: [later, sooner], at: t0)?.id == "later")
        #expect(scheduler.nextAlert(in: [later, sooner], at: t0) == nil)
    }

    @Test func honoursLeadTimeChanges() {
        var scheduler = AlertScheduler(leadTime: 60)
        let meeting = Meeting.fixture(startsIn: 240)
        #expect(scheduler.nextAlert(in: [meeting], at: t0) == nil)
        scheduler.leadTime = 300
        #expect(scheduler.nextAlert(in: [meeting], at: t0) == meeting)
    }
}
