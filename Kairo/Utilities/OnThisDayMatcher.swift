//
//  OnThisDayMatcher.swift
//  Kairo
//
//  Created by Andrii Kovner on 16.11.26.
//

import Foundation

enum OnThisDayMatcher {
    
    // MARK: - Matching
    
    static func isMatch(
        entryDate: Date,
        referenceDate: Date,
        calendar: Calendar
    ) -> Bool {
        let entryComponents = calendar.dateComponents(
            [.month, .day, .isLeapMonth],
            from: entryDate
        )

        let referenceComponents = calendar.dateComponents(
            [.month, .day, .isLeapMonth],
            from: referenceDate
        )

        guard let entryMonth = entryComponents.month,
              let entryDay = entryComponents.day,
              let referenceMonth = referenceComponents.month,
              let referenceDay = referenceComponents.day else {
            return false
        }

        return calendar.compare(
            entryDate,
            to: referenceDate,
            toGranularity: .year
        ) == .orderedAscending
            && entryMonth == referenceMonth
            && entryDay == referenceDay
            && entryComponents.isLeapMonth == referenceComponents.isLeapMonth
    }
    
    // MARK: - Years Ago
    
    static func yearsAgo(
        entryDate: Date,
        referenceDate: Date,
        calendar: Calendar
    ) -> Int? {
        guard isMatch(
            entryDate: entryDate,
            referenceDate: referenceDate,
            calendar: calendar
        ),
        let entryYearStart = calendar.dateInterval(
            of: .year,
            for: entryDate
        )?.start,
        let referenceYearStart = calendar.dateInterval(
            of: .year,
            for: referenceDate
        )?.start else {
            return nil
        }

        return calendar.dateComponents(
            [.year],
            from: entryYearStart,
            to: referenceYearStart
        ).year
    }
    
    // MARK: - Memories
    
    static func memories(
        from entries: [JournalEntry],
        referenceDate: Date,
        calendar: Calendar
    ) -> [JournalEntry] {
        entries
            .filter { entry in
                isMatch(
                    entryDate: entry.entryDate,
                    referenceDate: referenceDate,
                    calendar: calendar
                )
            }
            .sorted { first, second in
                let yearComparison = calendar.compare(
                    first.entryDate,
                    to: second.entryDate,
                    toGranularity: .year
                )

                if yearComparison != .orderedSame {
                    return yearComparison == .orderedDescending
                }
                
                if first.createdAt != second.createdAt {
                    return first.createdAt > second.createdAt
                }
                
                return first.id.uuidString < second.id.uuidString
            }
    }
}
