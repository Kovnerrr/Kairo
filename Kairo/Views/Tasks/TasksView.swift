//
//  TasksView.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import SwiftUI
import SwiftData
import Foundation

struct TasksView: View {
    // MARK: - Data
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @Query private var tasks: [TaskItem]
    
    // MARK: - State
    @State private var viewModel = TaskListViewModel()
    @State private var isFilterSheetPresented = false
    @State private var currentDate = Date.now
    @State private var taskToOpenID: UUID?
    
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
                                    referenceDate: currentDate,
                                    onToggleCompleted: {
                                        toggleTaskCompletion(task)
                                    },
                                    onOpenDetails: {
                                        taskToOpenID = task.id
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
                .onAppear {
                    currentDate = .now
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        currentDate = .now
                    }
                }
                .task {
                    for await _ in NotificationCenter.default.messages(
                        of: Calendar.self,
                        for: .calendarDayChanged
                    ) {
                        currentDate = .now
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $viewModel.searchText,
                    prompt: "Search tasks"
                )
                .navigationDestination(item: $taskToOpenID) { taskID in
                    if let task = tasks.first(where: { $0.id == taskID }) {
                        TaskDetailView(task: task)
                    } else {
                        ContentUnavailableView(
                            "Task Unavailable",
                            systemImage: "checklist",
                            description: Text(
                                "This task is no longer available."
                            )
                        )
                    }
                }
                .onChange(of: tasks.map(\.id)) { _, existingTaskIDs in
                    guard let openedTaskID = taskToOpenID else {
                        return
                    }

                    if !existingTaskIDs.contains(openedTaskID) {
                        taskToOpenID = nil
                    }
                }
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
                        .tint(AppTheme.accent)
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
                        .tint(AppTheme.accent)
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
    
    // MARK: - Actions
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

// MARK: - Previews

#Preview("Tasks") {
    TasksView()
        .modelContainer(PreviewContainer.container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Tasks - Long Text / Large Type") {
    let tasks = SampleData.tasks
    tasks[0].title =
        "Prepare a detailed review of the Calendar module and write down the next steps"

    let container = PreviewContainer.make(
        tasks: tasks,
        journalEntries: []
    )

    return TasksView()
        .modelContainer(container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
        .dynamicTypeSize(.accessibility3)
}

