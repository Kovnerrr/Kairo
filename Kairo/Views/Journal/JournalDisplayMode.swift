//
//  JournalDisplayMode.swift
//  Kairo
//
//  Created by Andrii Kovner on 12.11.26.
//

import Foundation

enum JournalDisplayMode: String, CaseIterable, Identifiable {
    case entries
    case photos
    
    var id: Self {
        self
    }
    
    var title: String {
        switch self {
        case .entries:
            return "Entries"
            
        case .photos:
            return "Photos"
        }
    }
}
