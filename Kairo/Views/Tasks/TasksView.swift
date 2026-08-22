//
//  TasksView.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import SwiftUI
import SwiftData

struct TasksView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @Query private var tasks: [TaskItem]
    
    // MARK: - State
    @State private var viewModel = TaskListViewModel()
    @State private var isFilterSheetPresented = false
    
    // MARK: - Computed Properties
    private var trimmedSearchText: String {
        viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var emptyStateSystemImageName: String {
        tasks.isEmpty ? "tray" : "magnifyingglass"
    }
    
    private var emptyStateTitle: String {
        if tasks.isEmpty {
            return "No tasks yet"
        }
        
        if !trimmedSearchText.isEmpty {
            return "No matching tasks"
        }
        
        switch viewModel.selectedFilter {
        case .all:
            return "No tasks"
        case .active:
            return "No active tasks"
        case .completed:
            return "No completed tasks"
        case .priority:
            return "No \(viewModel.selectedPriority.title.lowercased()) priority tasks"
        }
    }
    
    private var emptyStateMessage: String {
        if tasks.isEmpty {
            return "Tap the plus button to create your first task."
        }
        if !trimmedSearchText.isEmpty {
            return "Try changing your search text or filters."
        }
        
        switch viewModel.selectedFilter {
        case .all:
            return "Try creating a new task."
        case .active:
            return "Completed tasks are hidden by the current filter."
        case .completed:
            return "Complete a task and it will appear here."
        case .priority:
            return "Try selecting another priority or creating a matching task."
        }
    }
    
    // MARK: - Body
    var body: some View {
        let statistics = viewModel.statistics(from: tasks)
        let visibleTasks = viewModel.filteredAndSortedTasks(from: tasks)
        
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                AnimatedAppBackground()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                
                List {
                    Text("Kairo")
                        .font(AppTheme.Typography.appName)
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 6)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(
                            EdgeInsets(
                                top: 8,
                                leading: 20,
                                bottom: 8,
                                trailing: 20
                            )
                        )
                    Section {
                        StatisticsHeaderView(statistics: statistics)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    
                    Section("Tasks") {
                        if visibleTasks.isEmpty {
                            if tasks.isEmpty {
                                EmptyStateView(
                                    systemImageName: emptyStateSystemImageName,
                                    title: emptyStateTitle,
                                    message: emptyStateMessage,
                                    actionTitle: "Create Task",
                                    action: {
                                        viewModel.openCreateForm()
                                    }
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            } else {
                                EmptyStateView(
                                    systemImageName: emptyStateSystemImageName,
                                    title: emptyStateTitle,
                                    message: emptyStateMessage
                                )
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
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
                                    .tint(AppTheme.accentSoft)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $viewModel.searchText, prompt: "Search tasks")
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            isFilterSheetPresented = true
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease")

                                if viewModel.hasActiveTaskControls {
                                    Circle()
                                        .fill(AppTheme.accentSoft)
                                        .frame(width: 7, height: 7)
                                        .offset(x: 3, y: -3)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .tint(AppTheme.accentSoft)
                        .accessibilityLabel("Filter and sort tasks")
                        .accessibilityValue(
                            viewModel.hasActiveTaskControls
                                ? "Filters active"
                                : "Default settings"
                        )

                        Button {
                            viewModel.openCreateForm()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .tint(AppTheme.accentSoft)
                        .accessibilityLabel("Add Task")
                    }
                }
                .sheet(isPresented: $isFilterSheetPresented) {
                    TaskFilterSheetView(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
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
    TasksView()
        .modelContainer(PreviewContainer.container)
}

