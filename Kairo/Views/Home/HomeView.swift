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
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteTask(task)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    viewModel.openEditForm(for: task)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
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
                        navigationTitle: "New Task",
                        onCancel: {
                            viewModel.closeForm()
                        },
                        onSave: { formData in
                            createTask(from: formData)
                        }
                    )
                    
                case .edit(let task):
                    TaskFormView(
                        navigationTitle: "Edit Task",
                        initialData: TaskFormData(
                            title: task.title,
                            taskDescription: task.taskDescription,
                            dueDate: task.dueDate,
                            priority: task.priority,
                            category: task.category
                        ),
                        onCancel: {
                            viewModel.closeForm()
                        },
                        onSave: { formData in
                            updateTask(task, with: formData)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Private Methods
    private func createTask(from formData: TaskFormData) {
        let task = TaskItem(
            title: formData.title,
            taskDescription: formData.taskDescription,
            dueDate: formData.dueDate,
            priority: formData.priority,
            category: formData.category
        )
        modelContext.insert(task)
        viewModel.closeForm()
    }
    
    private func updateTask(_ task: TaskItem, with formData: TaskFormData) {
        task.title = formData.title
        task.taskDescription = formData.taskDescription
        task.dueDate = formData.dueDate
        task.priority = formData.priority
        task.category = formData.category
        
        viewModel.closeForm()
    }
    
    private func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
    }
    
    private func deleteTask(_ task: TaskItem) {
        modelContext.delete(task)
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewContainer.container)
}

