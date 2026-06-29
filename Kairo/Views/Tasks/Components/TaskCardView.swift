//
//  TaskCardView.swift
//  Kairo
//
//  Created by Andrii Kovner on 24.06.26.
//

import SwiftUI

struct TaskCardView: View {
    let task: TaskItem
    let onToggleCompleted: () -> Void
    
    private var formattedDueDate: String {
        task.dueDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var statusTitle: String {
        task.isCompleted ? "Completed" : "Active"
    }
    
    private var completionButtonImageName: String {
        task.isCompleted ? "checkmark.circle.fill" : "circle"
    }
    
    private var completionButtonAccessibilityLabel: String {
        task.isCompleted ? "Mark as active" : "Mark as completed"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Button {
                    onToggleCompleted()
                } label: {
                    Image(systemName: completionButtonImageName)
                        .font(.title3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(completionButtonAccessibilityLabel)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .strikethrough(task.isCompleted)
                    
                    if let description = task.taskDescription,
                       !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text(statusTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                metadataBadge(
                    title: task.category.title,
                    systemImageName: task.category.systemImageName
                )
                
                metadataBadge(title: task.priority.title)
                
                Text(formattedDueDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func metadataBadge(title: String, systemImageName: String? = nil) -> some View {
        HStack(spacing: 4) {
            if let systemImageName {
                Image(systemName: systemImageName)
            }
            
            Text(title)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.12), in: Capsule())
    }
}

#Preview {
    TaskCardView(task: SampleData.tasks[0], onToggleCompleted: {})
        .padding()
}
