//
//  TaskStatistics.swift
//  Kairo
//
//  Created by Andrii Kovner on 16.06.26.
//
import Foundation

/// A snapshot of calculated task statistics for the current task list.
struct TaskStatistics {
    
    // MARK: - Properties
    let total: Int
    let completed: Int
    let pending: Int
    
    // MARK: - Computed Properties
    var completionRate: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}
