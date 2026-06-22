//
//  TaskListViewModel.swift
//  Kairo
//
//  Created by Andrii Kovner on 18.06.26.
//

import Foundation
import Observation

@MainActor
@Observable
final class TaskListViewModel {
    
    // MARK: - List State
    var searchText: String = ""
    var selectedFilter: TaskFilter = .all
    var selectedSortOption: TaskSortOption = .dueDateAscending
    var selectedPriority: TaskPriority = .high
    
    // MARK: - Form Presentation
    var formRoute: TaskFormRoute?
    
    // MARK: - Form Actions
    func openCreateForm() {
        formRoute = .create
    }
    
    func openEditForm(for task: TaskItem) {
        formRoute = .edit(task)
    }
    
    func closeForm() {
        formRoute = nil
    }
    
    // MARK: - Search
    func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Task Processing
    func filteredAndSortedTasks(from tasks: [TaskItem]) -> [TaskItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchedTasks = tasks.filter { task in
            guard !query.isEmpty else { return true }
            
            let titleMatches = task.title.localizedCaseInsensitiveContains(query)
            let descriptionMatches =
            task.taskDescription?.localizedCaseInsensitiveContains(query) ?? false
            
            return titleMatches || descriptionMatches
        }
        
        let filteredTasks = searchedTasks.filter { task in
            switch selectedFilter {
            case .all: return true
            case .active: return !task.isCompleted
            case .completed: return task.isCompleted
            case .priority: return task.priority == selectedPriority
            }
        }
        
        return filteredTasks.sorted { firstTask, secondTask in
            switch selectedSortOption {
            case .dueDateAscending:
                return firstTask.dueDate < secondTask.dueDate
            case .dueDateDescending:
                return firstTask.dueDate > secondTask.dueDate
            case .priorityHighToLow:
                return firstTask.priority.sortWeight > secondTask.priority.sortWeight
            case .priorityLowToHigh:
                return firstTask.priority.sortWeight < secondTask.priority.sortWeight
            }
        }
    }
    
    // MARK: - Statistics
    func statistics(from tasks: [TaskItem]) -> TaskStatistics {
        let total = tasks.count
        
        let completed = tasks.filter { task in
            task.isCompleted
        }.count
        
        let pending = total - completed
        
        return TaskStatistics(total: total, completed: completed, pending: pending)
    }
}
