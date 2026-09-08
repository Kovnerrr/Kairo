//
//  TodayTaskRow.swift
//  Kairo
//
//  Created by Andrii Kovner on 23.08.26.
//

import SwiftUI

struct TodayTaskRow: View {
    // MARK: - Properties
    
    let task: TaskItem
    let onToggleCompleted: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleCompleted) {
                Image(
                    systemName: task.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.title3)
                .foregroundStyle(task.isCompleted ? AppTheme.accent : .secondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted
                    ? "Mark as active"
                    : "Mark as completed"
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundStyle(.primary)
                    .strikethrough(task.isCompleted)
                
                HStack(spacing: 8) {
                    Text(task.category.title)
                    
                    Text("•")
                        .accessibilityHidden(true)
                    
                    Text(task.priority.title)
                }
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AppTheme.cardCornerRadius
            )
            .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}
