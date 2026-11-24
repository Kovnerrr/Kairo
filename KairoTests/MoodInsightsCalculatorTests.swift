//
//  MoodInsightsCalculatorTests.swift
//  Kairo
//
//  Created by Andrii Kovner on 24.11.26.
//

import Foundation
import Testing
@testable import Kairo

@MainActor
struct MoodInsightsCalculatorTests {
    private let timeZone = TimeZone(identifier: "Europe/Berlin")!

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        return calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour
            )
        )!
    }
    
    @Test(arguments: [
        MoodInsightsPeriod.sevenDays,
        MoodInsightsPeriod.thirtyDays
    ])
    func emptyHistory(period: MoodInsightsPeriod) {
        let days = MoodInsightsCalculator.days(
            from: [],
            period: period,
            referenceDate: makeDate(
                year: 2026,
                month: 11,
                day: 20
            ),
            timeZone: timeZone
        )

        let summary = MoodInsightsSummary(days: days)

        #expect(summary.totalDays == period.rawValue)
        #expect(summary.daysTracked == 0)
        #expect(summary.missingDays == period.rawValue)
        #expect(days.allSatisfy { $0.mood == nil })
    }
    
    @Test
    func singleMood() {
        let referenceDate = makeDate(
            year: 2026,
            month: 11,
            day: 20
        )

        let mood = DailyMood(
            dayKey: "2026-11-18",
            mood: .good
        )

        let days = MoodInsightsCalculator.days(
            from: [mood],
            period: .sevenDays,
            referenceDate: referenceDate,
            timeZone: timeZone
        )

        let summary = MoodInsightsSummary(days: days)

        #expect(summary.totalDays == 7)
        #expect(summary.daysTracked == 1)
        #expect(summary.missingDays == 6)
        #expect(summary.count(for: .good) == 1)
        #expect(summary.count(for: .great) == 0)

        let november18 = days.first {
            $0.dayKey == "2026-11-18"
        }

        #expect(november18?.mood == .good)
    }
    
    @Test
    func periodBoundaries() {
        let moods = [
            DailyMood(dayKey: "2026-11-13", mood: .bad),
            DailyMood(dayKey: "2026-11-14", mood: .good),
            DailyMood(dayKey: "2026-11-20", mood: .great),
            DailyMood(dayKey: "2026-11-21", mood: .okay)
        ]

        let days = MoodInsightsCalculator.days(
            from: moods,
            period: .sevenDays,
            referenceDate: makeDate(
                year: 2026,
                month: 11,
                day: 20
            ),
            timeZone: timeZone
        )

        let summary = MoodInsightsSummary(days: days)

        #expect(days.first?.dayKey == "2026-11-14")
        #expect(days.last?.dayKey == "2026-11-20")

        #expect(summary.daysTracked == 2)
        #expect(summary.count(for: .good) == 1)
        #expect(summary.count(for: .great) == 1)
        #expect(summary.count(for: .bad) == 0)
        #expect(summary.count(for: .okay) == 0)
    }
    
    @Test
    func yearBoundary() {
        let days = MoodInsightsCalculator.days(
            from: [],
            period: .sevenDays,
            referenceDate: makeDate(
                year: 2027,
                month: 1,
                day: 2
            ),
            timeZone: timeZone
        )

        #expect(days.count == 7)
        #expect(days.first?.dayKey == "2026-12-27")
        #expect(days.last?.dayKey == "2027-01-02")
    }
    
    @Test
    func leapYear() {
        let days = MoodInsightsCalculator.days(
            from: [],
            period: .sevenDays,
            referenceDate: makeDate(
                year: 2028,
                month: 3,
                day: 2
            ),
            timeZone: timeZone
        )

        #expect(days.count == 7)
        #expect(days.contains { $0.dayKey == "2028-02-29" })
    }
    
    @Test
    func daylightSavingTime() {
        let days = MoodInsightsCalculator.days(
            from: [],
            period: .sevenDays,
            referenceDate: makeDate(
                year: 2027,
                month: 3,
                day: 30
            ),
            timeZone: timeZone
        )

        #expect(days.count == 7)
        #expect(days.first?.dayKey == "2027-03-24")
        #expect(days.last?.dayKey == "2027-03-30")

        let uniqueKeys = Set(days.map(\.dayKey))

        #expect(uniqueKeys.count == 7)
    }
    
    @Test
    func duplicateDayPrefersLatestUpdate() {
        let older = DailyMood(dayKey: "2026-11-18", mood: .good)
        let newer = DailyMood(dayKey: "2026-11-18", mood: .great)

        older.updatedAt = makeDate(year: 2026, month: 11, day: 18, hour: 10)
        newer.updatedAt = makeDate(year: 2026, month: 11, day: 18, hour: 15)

        let days = MoodInsightsCalculator.days(
            from: [older, newer],
            period: .sevenDays,
            referenceDate: makeDate(year: 2026, month: 11, day: 20),
            timeZone: timeZone
        )

        let summary = MoodInsightsSummary(days: days)

        #expect(days.first { $0.dayKey == "2026-11-18" }?.mood == .great)
        #expect(summary.daysTracked == 1)
    }
    
    @Test
    func inputOrderDoesNotChangeResult() {
        let older = DailyMood(dayKey: "2026-11-18", mood: .good)
        let newer = DailyMood(dayKey: "2026-11-18", mood: .bad)

        older.updatedAt = makeDate(year: 2026, month: 11, day: 18, hour: 9)
        newer.updatedAt = makeDate(year: 2026, month: 11, day: 18, hour: 17)

        let referenceDate = makeDate(year: 2026, month: 11, day: 20)

        let forward = MoodInsightsCalculator.days(
            from: [older, newer],
            period: .sevenDays,
            referenceDate: referenceDate,
            timeZone: timeZone
        )

        let reversed = MoodInsightsCalculator.days(
            from: [newer, older],
            period: .sevenDays,
            referenceDate: referenceDate,
            timeZone: timeZone
        )

        #expect(forward.map(\.dayKey) == reversed.map(\.dayKey))
        #expect(forward.map(\.mood) == reversed.map(\.mood))
        #expect(forward.first { $0.dayKey == "2026-11-18" }?.mood == .bad)
    }
    
    @Test
    func invalidMoodIsNotCountedAsOkay() {
        let invalid = DailyMood(dayKey: "2026-11-18", mood: .good)
        invalid.moodRawValue = "not-a-mood"

        let days = MoodInsightsCalculator.days(
            from: [invalid],
            period: .sevenDays,
            referenceDate: makeDate(year: 2026, month: 11, day: 20),
            timeZone: timeZone
        )

        let summary = MoodInsightsSummary(days: days)

        #expect(days.first { $0.dayKey == "2026-11-18" }?.mood == nil)
        #expect(summary.daysTracked == 0)
        #expect(summary.count(for: .okay) == 0)
    }
    
    @Test
    func distributionCountsEveryValidMoodOnce() {
        let moods = [
            DailyMood(dayKey: "2026-11-14", mood: .great),
            DailyMood(dayKey: "2026-11-15", mood: .good),
            DailyMood(dayKey: "2026-11-16", mood: .okay),
            DailyMood(dayKey: "2026-11-17", mood: .low),
            DailyMood(dayKey: "2026-11-18", mood: .bad)
        ]

        let days = MoodInsightsCalculator.days(
            from: moods,
            period: .sevenDays,
            referenceDate: makeDate(year: 2026, month: 11, day: 20),
            timeZone: timeZone
        )

        let summary = MoodInsightsSummary(days: days)

        let totalMoodCount = MoodType.allCases.reduce(0) {
            $0 + summary.count(for: $1)
        }

        #expect(summary.daysTracked == 5)
        #expect(summary.missingDays == 2)
        #expect(totalMoodCount == summary.daysTracked)
        #expect(MoodType.allCases.allSatisfy { summary.count(for: $0) == 1 })
    }
    
    @Test
    func referenceDateUsesSuppliedTimeZone() {
        let utc = TimeZone(secondsFromGMT: 0)!
        let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = utc

        let instant = utcCalendar.date(from: DateComponents(
            year: 2026,
            month: 11,
            day: 20,
            hour: 1
        ))!

        let utcDays = MoodInsightsCalculator.days(
            from: [],
            period: .sevenDays,
            referenceDate: instant,
            timeZone: utc
        )

        let losAngelesDays = MoodInsightsCalculator.days(
            from: [],
            period: .sevenDays,
            referenceDate: instant,
            timeZone: losAngeles
        )

        #expect(utcDays.last?.dayKey == "2026-11-20")
        #expect(losAngelesDays.last?.dayKey == "2026-11-19")
        #expect(utcDays.count == 7)
        #expect(losAngelesDays.count == 7)
    }
}
