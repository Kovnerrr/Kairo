//
//  OnThisDayMatcherTests.swift
//  Kairo
//
//  Created by Andrii Kovner on 19.11.26.
//
import Foundation
import Testing
@testable import Kairo

@MainActor
struct OnThisDayMatcherTests {
    // MARK: - Helpers
    
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0)!
        return result
    }
    
    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 12
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
    
    private func makeEntry(
        title: String,
        entryDate: Date,
        createdAt: Date? = nil,
        id: UUID = UUID()
    ) -> JournalEntry {
        JournalEntry(
            id: id,
            title: title,
            bodyText: "Test entry",
            entryDate: entryDate,
            createdAt: createdAt ?? date(2026, 11, 19)
        )
    }
    
    // MARK: - Matching
    
    @Test
    func matchesSameDayFromPreviousYear() {
        #expect(
            OnThisDayMatcher.isMatch(
                entryDate: date(2025, 11, 19),
                referenceDate: date(2026, 11, 19),
                calendar: calendar
            )
        )
    }
    
    @Test
    func doesNotMatchDifferentDay() {
        let result = OnThisDayMatcher.isMatch(
            entryDate: date(2025, 11, 18),
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(!result)
    }

    @Test
    func doesNotMatchDifferentMonth() {
        let result = OnThisDayMatcher.isMatch(
            entryDate: date(2025, 10, 19),
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(!result)
    }

    @Test
    func doesNotMatchCurrentYear() {
        let result = OnThisDayMatcher.isMatch(
            entryDate: date(2026, 11, 19),
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(!result)
    }
    
    // MARK: - Additional Matching Tests

    @Test
    func doesNotMatchFutureYear() {
        let result = OnThisDayMatcher.isMatch(
            entryDate: date(2027, 11, 19),
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(!result)
    }

    @Test
    func ignoresTimeOfDay() {
        let result = OnThisDayMatcher.isMatch(
            entryDate: date(2025, 11, 19, hour: 1),
            referenceDate: date(2026, 11, 19, hour: 23),
            calendar: calendar
        )

        #expect(result)
    }

    // MARK: - Years Ago Tests

    @Test
    func calculatesYearsAgo() {
        let result = OnThisDayMatcher.yearsAgo(
            entryDate: date(2022, 11, 19),
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(result == 4)
    }

    @Test
    func yearsAgoReturnsNilForNonMatchingDate() {
        let result = OnThisDayMatcher.yearsAgo(
            entryDate: date(2025, 11, 18),
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(result == nil)
    }

    // MARK: - Memories Tests

    @Test
    func memoriesFiltersOutNonMatchingEntries() {
        let matching = makeEntry(
            title: "Matching",
            entryDate: date(2025, 11, 19)
        )

        let differentDay = makeEntry(
            title: "Different day",
            entryDate: date(2025, 11, 18)
        )

        let currentYear = makeEntry(
            title: "Current year",
            entryDate: date(2026, 11, 19)
        )

        let futureYear = makeEntry(
            title: "Future year",
            entryDate: date(2027, 11, 19)
        )

        let result = OnThisDayMatcher.memories(
            from: [
                differentDay,
                futureYear,
                matching,
                currentYear
            ],
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(result.map(\.title) == ["Matching"])
    }

    @Test
    func memoriesReturnsEmptyArrayWhenNothingMatches() {
        let entry = makeEntry(
            title: "Other day",
            entryDate: date(2025, 11, 18)
        )

        let result = OnThisDayMatcher.memories(
            from: [entry],
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(result.isEmpty)
    }

    @Test
    func sortsMemoriesByYearDescending() {
        let entries = [
            makeEntry(
                title: "2023",
                entryDate: date(2023, 11, 19)
            ),
            makeEntry(
                title: "2025",
                entryDate: date(2025, 11, 19)
            ),
            makeEntry(
                title: "2024",
                entryDate: date(2024, 11, 19)
            )
        ]

        let result = OnThisDayMatcher.memories(
            from: entries,
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(
            result.map(\.title) == ["2025", "2024", "2023"]
        )
    }

    @Test
    func sortsSameYearByCreatedAtDescending() {
        let older = makeEntry(
            title: "Older creation",
            entryDate: date(2025, 11, 19, hour: 23),
            createdAt: date(2025, 11, 20)
        )

        let newer = makeEntry(
            title: "Newer creation",
            entryDate: date(2025, 11, 19, hour: 1),
            createdAt: date(2025, 12, 1)
        )

        let result = OnThisDayMatcher.memories(
            from: [older, newer],
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(
            result.map(\.title) == [
                "Newer creation",
                "Older creation"
            ]
        )
    }

    @Test
    func sortsTiedMemoriesByUUIDAscending() {
        let timestamp = date(2025, 12, 1)

        let firstID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000001"
        )!

        let secondID = UUID(
            uuidString: "00000000-0000-0000-0000-000000000002"
        )!

        let second = makeEntry(
            title: "Second UUID",
            entryDate: date(2025, 11, 19),
            createdAt: timestamp,
            id: secondID
        )

        let first = makeEntry(
            title: "First UUID",
            entryDate: date(2025, 11, 19),
            createdAt: timestamp,
            id: firstID
        )

        let result = OnThisDayMatcher.memories(
            from: [second, first],
            referenceDate: date(2026, 11, 19),
            calendar: calendar
        )

        #expect(
            result.map(\.title) == [
                "First UUID",
                "Second UUID"
            ]
        )
    }

    // MARK: - Leap Day Tests

    @Test
    func matchesLeapDayExactly() {
        let leapDayMatch = OnThisDayMatcher.isMatch(
            entryDate: date(2024, 2, 29),
            referenceDate: date(2028, 2, 29),
            calendar: calendar
        )

        let february28 = OnThisDayMatcher.isMatch(
            entryDate: date(2024, 2, 29),
            referenceDate: date(2026, 2, 28),
            calendar: calendar
        )

        let march1 = OnThisDayMatcher.isMatch(
            entryDate: date(2024, 2, 29),
            referenceDate: date(2026, 3, 1),
            calendar: calendar
        )

        #expect(leapDayMatch)
        #expect(!february28)
        #expect(!march1)
    }
    
    // MARK: - Calendar Era Tests

    @Test(arguments: [1990, 2018, 2019, 2025])
    func calculatesYearsAcrossJapaneseEras(entryYear: Int) {
        var japaneseCalendar = Calendar(identifier: .japanese)
        japaneseCalendar.timeZone = calendar.timeZone

        let entryDate = date(entryYear, 11, 19, hour: 23)
        let referenceDate = date(2026, 11, 19, hour: 1)

        #expect(
            OnThisDayMatcher.isMatch(
                entryDate: entryDate,
                referenceDate: referenceDate,
                calendar: japaneseCalendar
            )
        )

        #expect(
            OnThisDayMatcher.yearsAgo(
                entryDate: entryDate,
                referenceDate: referenceDate,
                calendar: japaneseCalendar
            ) == 2026 - entryYear
        )
    }

    @Test
    func sortsMemoriesAcrossJapaneseEras() {
        var japaneseCalendar = Calendar(identifier: .japanese)
        japaneseCalendar.timeZone = calendar.timeZone

        let older = makeEntry(
            title: "1994",
            entryDate: date(1994, 11, 19)
        )

        let newer = makeEntry(
            title: "2020",
            entryDate: date(2020, 11, 19)
        )

        let result = OnThisDayMatcher.memories(
            from: [older, newer],
            referenceDate: date(2026, 11, 19),
            calendar: japaneseCalendar
        )

        #expect(result.map(\.title) == ["2020", "1994"])
    }
}
