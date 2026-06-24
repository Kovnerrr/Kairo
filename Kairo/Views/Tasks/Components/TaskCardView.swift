//
//  TaskCardView.swift
//  Kairo
//
//  Created by Andrii Kovner on 24.06.26.
//

import SwiftUI

struct TaskCardView: View {
    let task: TaskItem
    
    private var formattedDueDate: String {
        task.dueDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var statusTitle: String {
        task.isCompleted ? "Completed" : "Active"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    
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
                Text(task.category.title)
                Text(task.priority.title)
                Text(formattedDueDate)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TaskCardView(task: SampleData.tasks[0])
        .padding()
}
