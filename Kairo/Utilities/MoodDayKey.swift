//
//  MoodDayKey.swift
//  Kairo
//
//  Created by Andrii Kovner on 19.10.26.
//

import Foundation

/// Builds a Gregorian day key using the current time zone.
enum MoodDayKey {
    static func make(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        
        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
}
