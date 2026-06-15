//
//  TaskItem.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.06.26.
//

import Foundation
import SwiftData

/// A persisted task entity stored locally with SwiftData
@Model
final class TaskItem {
    // MARK: - Stored Properties
    
    /// A stable unique identifier for the task
    @Attribute(.unique) var id: UUID
    
    /// Main task title show in the last list.
    var title: String
    
    /// Optional longer text with additional task details
    var taskDescription: String?
    
    /// Date when the task should be completed
    var dueDate: Date
    
    /// Indicates whether the task is completed
    var isCompleted: Bool
    
    /// Date when the task was created
    var createdAt: Date
    
    /// Date when the task was completed. Nil means that the task is still active
    var completedAt: Date?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        title: String,
        taskDescription: String? = nil,
        dueDate: Date = .now,
        isCompleted: Bool = false,
        createdAt: Date = .now,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}
