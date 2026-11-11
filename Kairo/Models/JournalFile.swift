//
//  JournalFile.swift
//  Kairo
//
//  Created by Andrii Kovner on 04.11.26.
//

import Foundation
import SwiftData

@Model
final class JournalFile {
    
    // MARK: - Properties
    
    @Attribute(.unique)
    var id: UUID
    var displayName: String
    var storedFileName: String
    var contentTypeIdentifier: String
    var fileSize: Int64
    var position: Int
    var createdAt: Date
    
    // MARK: - Relationships
    
    var entry: JournalEntry?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        displayName: String,
        storedFileName: String,
        contentTypeIdentifier: String,
        fileSize: Int64,
        position: Int,
        createdAt: Date = .now,
        entry: JournalEntry? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.storedFileName = storedFileName
        self.contentTypeIdentifier = contentTypeIdentifier
        self.fileSize = fileSize
        self.position = position
        self.createdAt = createdAt
        self.entry = entry
    }
}
