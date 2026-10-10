//
//  JournalEntryFormData.swift
//  Kairo
//
//  Created by Andrii Kovner on 06.10.26.
//

import Foundation

struct JournalEntryFormData {
    // MARK: - Stored Properties
    
    var title: String
    var bodyText: String
    var entryDate: Date
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Initialization
    
    init(title: String = "", bodyText: String = "", entryDate: Date = .now) {
        self.title = title
        self.bodyText = bodyText
        self.entryDate = entryDate
    }
    
    init(entry: JournalEntry) {
        self.title = entry.title
        self.bodyText = entry.bodyText
        self.entryDate = entry.entryDate
    }
}
