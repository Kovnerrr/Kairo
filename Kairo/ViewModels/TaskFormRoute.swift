//
//  TaskFormRoute.swift
//  Kairo
//
//  Created by Andrii Kovner on 18.06.26.
//

import Foundation

/// Describes why the task form is presented.
enum TaskFormRoute: Identifiable {
    case create
    case edit(TaskItem)
    
    // MARK: - Identifiable
    var id: String {
        switch self {
        case .create: "create"
        case .edit(let task): "edit-\(task.id.uuidString)"
        }
    }
    
    // MARK: - Associated Data
    var task: TaskItem? {
        switch self {
        case .create: nil
        case .edit(let task): task
        }
    }
}
