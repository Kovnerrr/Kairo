//
//  TaskFilter.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.06.26.
//

import Foundation

/// Describes which tasks should be visible in the list.
enum TaskFilter: String, CaseIterable, Identifiable, Codable {
    case all
    case active
    case completed
    case priority
    
    // MARK: - Identifiable
    var id: String { rawValue }
    
    // MARK: - Display
    var title: String {
        switch self {
        case .all: "All"
        case .active: "Active"
        case .completed: "Completed"
        case .priority: "Priority"
        }
    }
}
