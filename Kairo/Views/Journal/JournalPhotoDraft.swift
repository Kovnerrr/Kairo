//
//  JournalPhotoDraft.swift
//  Kairo
//
//  Created by Andrii Kovner on 02.11.26.
//

import Foundation

struct JournalPhotoDraft: Identifiable {
    
    // MARK: - Source
    
    enum Source {
        case existing
        case imported(imageData: Data)
    }
    
    // MARK: - Properties
    
    let id: UUID
    let thumbnailData: Data
    let source: Source
    
    // MARK: - Initialization
    
    init(id: UUID, thumbnailData: Data, source: Source) {
        self.id = id
        self.thumbnailData = thumbnailData
        self.source = source
    }
}
