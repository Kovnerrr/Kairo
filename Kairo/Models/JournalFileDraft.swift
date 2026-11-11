//
//  JournalFileDraft.swift
//  Kairo
//
//  Created by Andrii Kovner on 10.11.26.
//

import Foundation

enum JournalFileDraft: Identifiable, Sendable {
    case existing(
        id: UUID,
        displayName: String,
        storedFileName: String,
        contentTypeIdentifier: String,
        fileSize: Int64
    )
    
    case imported(ImportedJournalFile)
    
    var id: UUID {
        switch self {
        case .existing(let id, _, _, _, _):
            return id
            
        case .imported(let file):
            return file.id
        }
    }
}
