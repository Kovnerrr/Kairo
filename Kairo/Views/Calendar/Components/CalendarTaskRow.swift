//
//  CalendarTaskRow.swift
//  Kairo
//
//  Created by Andrii Kovner on 20.10.26.
//

import SwiftUI

struct CalendarTaskRow: View {
    // MARK: - Properties
    
    let task: TaskItem
    let onToggleCompleted: () -> Void
    let onOpenDetails: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                onToggleCompleted()
            } label: {
                Image(
                    systemName: task.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(task.isCompleted ? AppTheme.accent : .secondary)
                .font(.title3)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted
                    ? "Mark \(task.title) as active"
                    : "Mark \(task.title) as completed"
            )
            
            Button {
                onOpenDetails()
            } label: {
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.title)
                            .font(AppTheme.Typography.cardTitle)
                            .strikethrough(task.isCompleted)
                            .foregroundStyle(.primary)

                        Text(task.category.title)
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Text(task.priority.title)
                        .font(AppTheme.Typography.badge)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.title)
            .accessibilityValue(
                """
                Category: \(task.category.title).
                Priority: \(task.priority.title).
                Status: \(task.isCompleted ? "Completed" : "Active").
                """
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
    }
}

// MARK: - Previews

#Preview("All Task States") {
    VStack(alignment: .leading, spacing: 20) {

        Text("High Priority")
            .font(AppTheme.Typography.sectionTitle)

        CalendarTaskRow(
            task: TaskItem(
                title: "Finish SwiftUI project",
                dueDate: .now,
                priority: .high
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )

        Text("Medium Priority")
            .font(AppTheme.Typography.sectionTitle)

        CalendarTaskRow(
            task: TaskItem(
                title: "Study German",
                dueDate: .now,
                priority: .medium
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )

        Text("Low Priority")
            .font(AppTheme.Typography.sectionTitle)

        CalendarTaskRow(
            task: TaskItem(
                title: "Buy groceries",
                dueDate: .now,
                priority: .low
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )

        Text("Completed")
            .font(AppTheme.Typography.sectionTitle)

        CalendarTaskRow(
            task: TaskItem(
                title: "Review SwiftData models",
                dueDate: .now,
                priority: .high,
                isCompleted: true,
                completedAt: .now
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )

        Text("Long Title")
            .font(AppTheme.Typography.sectionTitle)

        CalendarTaskRow(
            task: TaskItem(
                title: "Complete the implementation and testing of the calendar module",
                dueDate: .now,
                priority: .medium
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )
    }
    .padding()
    .background(AppTheme.background)
}

#Preview("Dark Mode") {
    VStack(spacing: 12) {
        CalendarTaskRow(
            task: TaskItem(
                title: "Finish SwiftUI project",
                dueDate: .now,
                priority: .high
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )

        CalendarTaskRow(
            task: TaskItem(
                title: "Completed task",
                dueDate: .now,
                priority: .low,
                isCompleted: true,
                completedAt: .now
            ),
            onToggleCompleted: {},
            onOpenDetails: {}
        )
    }
    .padding()
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}

#Preview("Accessibility") {
    CalendarTaskRow(
        task: TaskItem(
            title: "Prepare the presentation for the upcoming project review",
            dueDate: .now,
            priority: .high
        ),
        onToggleCompleted: {},
        onOpenDetails: {}
    )
    .padding()
    .background(AppTheme.background)
    .environment(
        \.dynamicTypeSize,
        .accessibility3
    )
}
