//
//  TaskFormData.swift
//  Kairo
//
//  Created by Andrii Kovner on 01.07.26.
//

import Foundation

struct TaskFormData {
    let title: String
    let taskDescription: String?
    let dueDate: Date
    let priority: TaskPriority
    let category: TaskCategory
    
    init(
        title: String = "",
        taskDescription: String? = nil,
        dueDate: Date = .now,
        priority: TaskPriority = .medium,
        category: TaskCategory = .personal
    ) {
        self.title = title
        self.taskDescription = taskDescription
        self.dueDate = dueDate
        self.priority = priority
        self.category = category
    }
}
