import Foundation
import Testing

@testable import PokeMeCore

/// Each test gets its own throwaway UserDefaults suite so nothing leaks into the real app preferences.
final class SettingsTests {
    private let suiteName = "PokeMeTests-\(UUID().uuidString)"
    private let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test func leadTimeDefaultsToOneMinute() {
        #expect(Settings(defaults: defaults).leadMinutes == 1)
    }

    @Test func leadTimePersistsAcrossInstances() {
        Settings(defaults: defaults).leadMinutes = 5
        #expect(Settings(defaults: defaults).leadMinutes == 5)
    }

    @Test func leadTimeIsNeverNegative() {
        let settings = Settings(defaults: defaults)
        settings.leadMinutes = -3
        #expect(settings.leadMinutes == 0)
    }

    @Test func calendarsAreEnabledByDefault() {
        #expect(Settings(defaults: defaults).isCalendarEnabled("work"))
    }

    @Test func togglingCalendarsPersistsAcrossInstances() {
        let settings = Settings(defaults: defaults)
        settings.setCalendar("work", enabled: false)
        settings.setCalendar("home", enabled: false)
        settings.setCalendar("home", enabled: true)

        let reloaded = Settings(defaults: defaults)
        #expect(!reloaded.isCalendarEnabled("work"))
        #expect(reloaded.isCalendarEnabled("home"))
        #expect(reloaded.disabledCalendarIDs == ["work"])
    }
}
