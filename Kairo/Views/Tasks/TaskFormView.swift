//
//  TaskFormView.swift
//  Kairo
//
//  Created by Andrii Kovner on 27.06.26.
//

import SwiftUI

struct TaskFormView: View {
    // MARK: - Form State
    
    @State private var title: String
    @State private var taskDescription: String
    @State private var dueDate: Date
    @State private var priority: TaskPriority
    @State private var category: TaskCategory
    
    // MARK: - Properties
    
    let navigationTitle: String
    
    // MARK: - Actions
    
    let onCancel: () -> Void
    let onSave: (TaskFormData) -> Void
    
    // MARK: - Initialization
    
    init(
        navigationTitle: String,
        initialData: TaskFormData = TaskFormData(),
        onCancel: @escaping () -> Void,
        onSave: @escaping (TaskFormData) -> Void
    ) {
        self._title = State(initialValue: initialData.title)
        self._taskDescription = State(initialValue: initialData.taskDescription ?? "")
        self._dueDate = State(initialValue: initialData.dueDate)
        self._priority = State(initialValue: initialData.priority)
        self._category = State(initialValue: initialData.category)
        self.navigationTitle = navigationTitle
        self.onCancel = onCancel
        self.onSave = onSave
    }
    
    // MARK: - Computed Properties
    
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private var trimmedDescription: String? {
        let trimmedValue = taskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
    
    private var formData: TaskFormData {
        TaskFormData(
            title: trimmedTitle,
            taskDescription: trimmedDescription,
            dueDate: dueDate,
            priority: priority,
            category: category
        )
    }
    
    private var isSaveDisabled: Bool {
        trimmedTitle.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField(
                        "Description",
                        text: $taskDescription,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
                
                Section("Schedule") {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: .date
                    )
                }
                
                Section("Organization") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Text(priority.title).tag(priority)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(TaskCategory.allCases) { category in
                            Text(category.title).tag(category)
                        }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(formData)
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}

#Preview("Create") {
    TaskFormView(
        navigationTitle: "New Task",
        onCancel: {},
        onSave: { _ in }
    )
}

#Preview("Edit") {
    TaskFormView(
        navigationTitle: "Edit Task",
        initialData: TaskFormData(
            title: "Prepare app screenshots",
            taskDescription: "Make screenshots for the portfolio README.",
            dueDate: .now,
            priority: .high,
            category: .work
        ),
        onCancel: {},
        onSave: { _ in }
    )
}
