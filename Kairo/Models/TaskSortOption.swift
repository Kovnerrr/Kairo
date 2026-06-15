//
//  TaskSortOption.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.06.26.
//

import Foundation

///Describes how tasks should be ordered in the list.
enum TaskSortOption: String, CaseIterable, Identifiable, Codable {
    case dueDateAscending
    case dueDateDescending
    case priorityHighToLow
    case priorityLowToHigh
    
    // MARK: - Identifiable
    var id: String { rawValue }
    
    // MARK: - Display
    var title: String {
        switch self {
        case .dueDateAscending: "Due Date ↑"
        case .dueDateDescending: "Due Date ↓"
        case .priorityHighToLow: "Priority: High to Low"
        case .priorityLowToHigh: "Priority: Low to High"
        }
    }
}
