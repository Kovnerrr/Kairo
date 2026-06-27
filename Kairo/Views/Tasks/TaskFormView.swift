//
//  TaskFormView.swift
//  Kairo
//
//  Created by Andrii Kovner on 27.06.26.
//

import SwiftUI

struct TaskFormView: View {
    // MARK: - Form State
    
    @State private var title: String = ""
    @State private var taskDescription: String = ""
    @State private var dueDate: Date = .now
    @State private var priority: TaskPriority = .medium
    @State private var category: TaskCategory = .personal
    
    // MARK: - Actions
    
    let onCancel: () -> Void
    let onSave: () -> Void
    
    // MARK: - Computed Properties
    
    private var isSaveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(isSaveDisabled)
                }
            }
        }
    }
}

#Preview {
    TaskFormView(
        onCancel: {},
        onSave: {}
    )
}
