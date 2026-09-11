//
//  DailyMood.swift
//  Kairo
//
//  Created by Andrii Kovner on 08.09.26.
//

import Foundation
import SwiftData

@Model
final class DailyMood {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var dayKey: String
    
    var moodRawValue: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        dayKey: String,
        mood: MoodType,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dayKey = dayKey
        self.moodRawValue = mood.rawValue
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    var mood: MoodType {
        get {
            MoodType(rawValue: moodRawValue) ?? .okay
        }
        set {
            moodRawValue = newValue.rawValue
        }
    }
}
