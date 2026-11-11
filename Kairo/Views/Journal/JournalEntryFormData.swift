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
    var photos: [JournalPhotoDraft] = []
    var files: [JournalFileDraft] = []
    
    // MARK: - Computed Properties
    
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        photos.count <= 5 &&
        files.count <= 3 &&
        Set(photos.map(\.id)).count == photos.count &&
        Set(files.map(\.id)).count == files.count
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
        
        // Load existing photos.
        self.photos = entry.photos
            .sorted { $0.position < $1.position }
            .map { photo in
                JournalPhotoDraft(
                    id: photo.id,
                    thumbnailData: photo.thumbnailData,
                    source: .existing
                )
            }
        
        // Load existing documents.
        self.files = entry.files
            .sorted { $0.position < $1.position }
            .map { file in
                JournalFileDraft.existing(
                    id: file.id,
                    displayName: file.displayName,
                    storedFileName: file.storedFileName,
                    contentTypeIdentifier: file.contentTypeIdentifier,
                    fileSize: file.fileSize
                )
            }
    }
}

// MARK: - Save Errors

enum JournalEntrySaveError: LocalizedError {
    case invalidForm
    case entryUnavailable
    case attachmentUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidForm:
            "Check the entry text and attachment limits."

        case .entryUnavailable:
            "This journal entry is no longer available."

        case .attachmentUnavailable:
            "An attachment is no longer available. Reopen the entry and try again."
        }
    }
}
