//
//  JournalEntry.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.09.26.
//

import Foundation
import SwiftData

@Model
final class JournalEntry {
    // MARK: - Stored Properties
    
    @Attribute(.unique) var id: UUID
    
    var title: String
    var bodyText: String
    var entryDate: Date
    var createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        title: String,
        bodyText: String,
        entryDate: Date = .now,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.bodyText = bodyText
        self.entryDate = entryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
