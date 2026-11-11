//
//  ImportedJournalFile.swift
//  Kairo
//
//  Created by Andrii Kovner on 04.11.26.
//

import Foundation

struct ImportedJournalFile: Sendable, Identifiable {
    let id: UUID
    let displayName: String
    let temporaryURL: URL
    let contentTypeIdentifier: String
    let fileSize: Int64
    let formSessionID: UUID
}
