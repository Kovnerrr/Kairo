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
    
    private var isOverdue: Bool {
        guard !task.isCompleted else { return false }
        return Calendar.current
            .startOfDay(for: task.dueDate) < Calendar.current.startOfDay(for: .now)
    }
    
    private var dueDateText: String {
        if isOverdue {
            return "Overdue"
        }
        
        if Calendar.current.isDateInToday(task.dueDate) {
            return "Today"
        }
        
        if Calendar.current.isDateInTomorrow(task.dueDate) {
            return "Tomorrow"
        }
        
        return task.dueDate.formatted(date: .abbreviated, time: .omitted)
    }
    
    private var dueDateSystemImageName: String {
        isOverdue ? "exclamationmark.triangle" : "calendar"
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
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(completionButtonAccessibilityLabel)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(AppTheme.Typography.cardTitle)
                        .strikethrough(task.isCompleted)
                    
                    if let description = task.taskDescription,
                       !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(description)
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text(statusTitle)
                    .font(AppTheme.Typography.badge)
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                metadataBadge(
                    title: task.category.title,
                    systemImageName: task.category.systemImageName
                )
                
                metadataBadge(
                    title: task.priority.title,
                    systemImageName: task.priority.systemImageName
                )
                
                metadataBadge(
                    title: dueDateText,
                    systemImageName: dueDateSystemImageName,
                    isProminent: isOverdue
                )
            }
        }
        .padding()
        .background(
            AppTheme.surface,
            in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .padding(.vertical, 4)
    }
    
    private func metadataBadge(
        title: String,
        systemImageName: String? = nil,
        isProminent: Bool = false
    ) -> some View {
        HStack(spacing: 4) {
            if let systemImageName {
                Image(systemName: systemImageName)
            }
            
            Text(title)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(AppTheme.Typography.badge)
        .foregroundStyle(isProminent ? Color.red : Color.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            isProminent ? Color.red.opacity(0.12) : AppTheme.accentSoft,
            in: Capsule()
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}

#Preview("Active") {
    TaskCardView(task: SampleData.tasks[0], onToggleCompleted: {})
        .padding()
        .background(AppTheme.background)
}

#Preview("Completed") {
    TaskCardView(
        task: TaskItem(
            title: "Completed task",
            dueDate: .now,
            priority: .medium,
            category: .work,
            isCompleted: true,
            completedAt: .now
        ),
        onToggleCompleted: {}
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("Overdue") {
    TaskCardView(
        task: TaskItem(
            title: "Overdue task",
            dueDate: Calendar.current
                .date(
                    byAdding: .day,
                    value: -1,
                    to: .now
                ) ?? .now,
            priority: .high,
            category: .study
        ),
        onToggleCompleted: {}
    )
    .padding()
    .background(AppTheme.background)
}
