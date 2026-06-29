//
//  HomeView.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    
    // MARK: - State
    @State private var viewModel = TaskListViewModel()
    
    // MARK: - Body
    var body: some View {
        let statistics = viewModel.statistics(from: tasks)
        let visibleTasks = viewModel.filteredAndSortedTasks(from: tasks)
        
        NavigationStack {
            List {
                Section {
                    StatisticsHeaderView(statistics: statistics)
                }
                
                Section("Tasks") {
                    if visibleTasks.isEmpty {
                        EmptyStateView(
                            systemImageName: "tray",
                            title: "No tasks yet",
                            message: "Tap the plus button to create your first task"
                        )
                    } else {
                        ForEach(visibleTasks, id: \.id) { task in
                            TaskCardView(
                                task: task,
                                onToggleCompleted: {
                                    toggleTaskCompletion(task)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Kairo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.openCreateForm()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Task")
                }
            }
            .sheet(item: $viewModel.formRoute) { route in
                switch route {
                case .create:
                    TaskFormView(
                        onCancel: {
                            viewModel.closeForm()
                        },
                        onSave: { title, taskDescription, dueDate, priority, category in createTask(
                            title: title,
                            taskDescription: taskDescription,
                            dueDate: dueDate,
                            priority: priority,
                            category: category
                        )
                        }
                    )
                    
                case .edit(let task):
                    Text("Edit task: \(task.title)")
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func createTask(
        title: String,
        taskDescription: String?,
        dueDate: Date,
        priority: TaskPriority,
        category: TaskCategory
    ) {
        let task = TaskItem(
            title: title,
            taskDescription: taskDescription,
            dueDate: dueDate,
            priority: priority,
            category: category
        )
        
        modelContext.insert(task)
        viewModel.closeForm()
    }
    
    private func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewContainer.container)
}
