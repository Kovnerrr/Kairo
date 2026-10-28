//
//  TaskCardView.swift
//  Kairo
//
//  Created by Andrii Kovner on 24.06.26.
//

import SwiftUI

struct TaskCardView: View {
    
    // MARK: - Properties
    
    let task: TaskItem
    let referenceDate: Date
    let onToggleCompleted: () -> Void
    let onOpenDetails: () -> Void
    
    // MARK: - Computed Properties
    
    private var isOverdue: Bool {
        guard !task.isCompleted else {
            return false
        }

        let calendar = Calendar.current

        return calendar.startOfDay(for: task.dueDate)
            < calendar.startOfDay(for: referenceDate)
    }

    private var dueDateText: String {
        let calendar = Calendar.current

        if isOverdue {
            return "Overdue"
        }

        if calendar.isDate(task.dueDate, inSameDayAs: referenceDate) {
            return "Today"
        }

        if let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: referenceDate)
        ),
           calendar.isDate(task.dueDate, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }

        return task.dueDate.formatted(
            date: .abbreviated,
            time: .omitted
        )
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
        task.isCompleted ? "Mark \(task.title) as active" : "Mark \(task.title) as completed"
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button {
                onToggleCompleted()
            } label: {
                Image(systemName: completionButtonImageName)
                    .foregroundStyle(
                        task.isCompleted ? AppTheme.accent : .secondary
                    )
                    .font(.title3)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(completionButtonAccessibilityLabel)

            Button {
                onOpenDetails()
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(AppTheme.Typography.cardTitle)
                                .strikethrough(task.isCompleted)

                            if let description = task.taskDescription,
                               !description.trimmingCharacters(
                                   in: .whitespacesAndNewlines
                               ).isEmpty {
                                Text(description)
                                    .font(AppTheme.Typography.secondary)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }

                        Spacer(minLength: 8)

                        Text(statusTitle)
                            .font(AppTheme.Typography.badge)
                            .foregroundStyle(.secondary)
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) {
                            taskMetadata
                        }
                        .fixedSize(horizontal: true, vertical: false)

                        VStack(alignment: .leading, spacing: 8) {
                            taskMetadata
                        }
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: 44,
                    alignment: .leading
                )
                .foregroundStyle(.primary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityValue(
                "\(statusTitle), \(task.category.title), \(task.priority.title) priority, \(dueDateText)"
            )
            .accessibilityHint("Opens task details")
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
    
    // MARK: - Subviews

        @ViewBuilder
        private var taskMetadata: some View {
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
    
    // MARK: - Helpers
    
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

// MARK: - Previews

#Preview("Active") {
    TaskCardView(
        task: SampleData.tasks[0],
        referenceDate: .now,
        onToggleCompleted: {},
        onOpenDetails: {}
    )
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
        referenceDate: .now,
        onToggleCompleted: {},
        onOpenDetails: {}
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
        referenceDate: .now,
        onToggleCompleted: {},
        onOpenDetails: {}
    )
    .padding()
    .background(AppTheme.background)
}
