//
//  MoodInsightsCalculator.swift
//  Kairo
//
//  Created by Andrii Kovner on 20.11.26.
//

import Foundation

// MARK: - Period

enum MoodInsightsPeriod: Int, CaseIterable, Identifiable {
    case sevenDays = 7
    case thirtyDays = 30
    
    var id: Int {
        rawValue
    }
    
    var title: String {
        switch self {
        case .sevenDays:
            return "7 Days"
        case .thirtyDays:
            return "30 Days"
        }
    }
}

// MARK: - Day

struct MoodInsightsDay: Identifiable {
    let dayKey: String
    let date: Date
    let mood: MoodType?
    
    var id: String {
        dayKey
    }
}

// MARK: - Summary

struct MoodInsightsSummary {
    let days: [MoodInsightsDay]
    
    var totalDays: Int {
        days.count
    }
    
    var daysTracked: Int {
        days.filter { $0.mood != nil}.count
    }
    
    var missingDays: Int {
        totalDays - daysTracked
    }
    
    func count(for mood: MoodType) -> Int {
        days.filter { $0.mood == mood}.count
    }
}

// MARK: - Calculator

enum MoodInsightsCalculator {
    static func days(
        from moods: [DailyMood],
        period: MoodInsightsPeriod,
        referenceDate: Date,
        timeZone: TimeZone
    ) -> [MoodInsightsDay] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        
        guard let today = calendar.dateInterval(
            of: .day,
            for: referenceDate
        )?.start else {
            return []
        }
        
        var moodsByDay: [String: DailyMood] = [:]
        
        for mood in moods {
            guard let existing = moodsByDay[mood.dayKey] else {
                moodsByDay[mood.dayKey] = mood
                continue
            }
            
            if mood.updatedAt > existing.updatedAt ||
                (mood.updatedAt == existing.updatedAt && mood.createdAt > existing.createdAt) ||
                (mood.updatedAt == existing.updatedAt &&
                 mood.createdAt == existing.createdAt &&
                 mood.id.uuidString < existing.id.uuidString) {
                moodsByDay[mood.dayKey] = mood
            }
        }
        
        var result: [MoodInsightsDay] = []
        
        for offset in (0..<period.rawValue).reversed() {
            guard let day = calendar.date(
                byAdding: .day,
                value: -offset,
                to: today
            ) else {
                continue
            }
            
            let components = calendar.dateComponents(
                [.year, .month, .day],
                from: day
            )
            
            guard let year = components.year,
                  let month = components.month,
                  let dayNumber = components.day else {
                continue
            }
            
            let dayKey = String(
                format: "%04d-%02d-%02d",
                year,
                month,
                dayNumber
            )
            
            let mood = moodsByDay[dayKey].flatMap {
                MoodType(rawValue: $0.moodRawValue)
            }
            
            result.append(
                MoodInsightsDay(
                    dayKey: dayKey,
                    date: day,
                    mood: mood
                )
            )
        }
        return result
    }
}
