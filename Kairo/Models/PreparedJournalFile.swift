//
//  PreparedJournalFile.swift
//  Kairo
//
//  Created by Andrii Kovner on 10.11.26.
//

import Foundation

struct PreparedJournalFile: Sendable, Identifiable {
    let id: UUID
    let displayName: String
    let storedFileName: String
    let contentTypeIdentifier: String
    let fileSize: Int64
    let permanentURL: URL
}
