//
//  TaskPriority.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.06.26.
//

import Foundation

///Describe how important a task is.
enum TaskPriority: String, CaseIterable, Identifiable, Codable {
    case low
    case medium
    case high
    
    // MARK: - Identifiable
    var id: String { rawValue }
    
    // MARK: - Display
    var title: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }
    
    // MARK: - Sorting
    var sortWeight: Int {
        switch self {
        case .low: 1
        case .medium: 2
        case .high: 3
        }
    }
}
