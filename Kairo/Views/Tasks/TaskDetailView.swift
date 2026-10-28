//
//  TaskDetailView.swift
//  Kairo
//
//  Created by Andrii Kovner on 27.10.26.
//

import SwiftUI
import SwiftData

struct TaskDetailView: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let task: TaskItem
    
    // MARK: - State
    
    @State private var isEditSheetPresented = false
    @State private var saveErrorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            AnimatedAppBackground()
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(task.title)
                        .font(AppTheme.Typography.detailTitle)
                    
                    if let description = task.taskDescription,
                       !description.isEmpty {
                        Text(description)
                            .font(AppTheme.Typography.body)
                            .foregroundStyle(.secondary)
                    }
                    
                    LabeledContent("Due Date") {
                        Text(task.dueDate, format: .dateTime.day().month(.wide).year())
                    }
                    
                    LabeledContent("Priority") {
                        Text(task.priority.title)
                    }
                    
                    LabeledContent("Category") {
                        Text(task.category.title)
                    }
                    
                    LabeledContent("Status") {
                        Label(
                            task.isCompleted ? "Completed" : "Not Completed",
                            systemImage: task.isCompleted
                            ? "checkmark.circle.fill"
                            : "circle"
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditSheetPresented = true
                }
            }
        }
        
        .sheet(isPresented: $isEditSheetPresented) {
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
                    isEditSheetPresented = false
                },
                onSave: { formData in
                    updateTask(with: formData)
                }
            )
            .alert(
                "Unable to Save Task",
                isPresented: Binding(
                    get: {
                        saveErrorMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            saveErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    // MARK: - Actions
    
    private func updateTask(with formData: TaskFormData) {
        let previousData = TaskFormData(
            title: task.title,
            taskDescription: task.taskDescription,
            dueDate: task.dueDate,
            priority: task.priority,
            category: task.category
        )
        
        task.title = formData.title
        task.taskDescription = formData.taskDescription
        task.dueDate = formData.dueDate
        task.priority = formData.priority
        task.category = formData.category
        
        do {
            try modelContext.save()
            isEditSheetPresented = false
        } catch {
            task.title = previousData.title
            task.taskDescription = previousData.taskDescription
            task.dueDate = previousData.dueDate
            task.priority = previousData.priority
            task.category = previousData.category
            
            saveErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("Task Details") {
    let task = TaskItem(
        title: "Study English",
        taskDescription: "Practice new words and review yesterday's notes.",
        dueDate: .now,
        priority: .high,
        category: .personal
    )

    let container = PreviewContainer.make(
        tasks: [task],
        journalEntries: []
    )

    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}

#Preview("Task Details - Completed") {
    let task = TaskItem(
        title: "Finish SwiftUI lesson",
        taskDescription: "Review navigation and SwiftData.",
        dueDate: .now,
        priority: .high,
        category: .personal,
        isCompleted: true,
        completedAt: .now
    )

    let container = PreviewContainer.make(
        tasks: [task],
        journalEntries: []
    )

    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}

#Preview("Task Details - No Description") {
    let task = TaskItem(
        title: "Plan tomorrow",
        taskDescription: nil,
        dueDate: .now,
        priority: .medium,
        category: .personal
    )

    let container = PreviewContainer.make(
        tasks: [task],
        journalEntries: []
    )

    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}

#Preview("Task Details - Dark Mode") {
    let task = TaskItem(
        title: "Study Swift",
        taskDescription: "Practice SwiftUI layouts.",
        dueDate: .now,
        priority: .high,
        category: .personal
    )

    let container = PreviewContainer.make(
        tasks: [task],
        journalEntries: []
    )

    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
    .preferredColorScheme(.dark)
}

#Preview("Task Details - Long Text + Accessibility (Dark)") {
    let task = TaskItem(
        title: "Prepare a detailed review of the Calendar module",
        taskDescription: """
        Review how the calendar displays tasks for the selected day.
        Check completed and incomplete tasks, navigation and editing.

        Make sure a long description remains readable with larger text.
        All task information should remain accessible by scrolling.

        Write down anything that needs improvement before starting
        the next module.
        """,
        dueDate: .now,
        priority: .high,
        category: .study
    )

    let container = PreviewContainer.make(
        tasks: [task],
        journalEntries: []
    )

    return NavigationStack {
        TaskDetailView(task: task)
    }
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
    .environment(\.dynamicTypeSize, .accessibility2)
    .preferredColorScheme(.dark)
}
