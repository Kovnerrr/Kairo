//
//  JournalPhoto.swift
//  Kairo
//
//  Created by Andrii Kovner on 29.10.26.
//

import Foundation
import SwiftData

@Model
final class JournalPhoto {
    
    // MARK: - Stored Properties
    
    @Attribute(.unique) var id: UUID
    @Attribute(.externalStorage) var imageData: Data
    @Attribute(.externalStorage) var thumbnailData: Data
    
    var position: Int
    var entry: JournalEntry?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        position: Int,
        imageData: Data,
        thumbnailData: Data,
        entry: JournalEntry? = nil
    ) {
        self.id = id
        self.position = position
        self.imageData = imageData
        self.thumbnailData = thumbnailData
        self.entry = entry
    }
}
