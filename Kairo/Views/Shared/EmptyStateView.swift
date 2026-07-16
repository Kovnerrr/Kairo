//
//  EmptyStateView.swift
//  Kairo
//
//  Created by Andrii Kovner on 25.06.26.
//

import SwiftUI

struct EmptyStateView: View {
    let systemImageName: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        systemImageName: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImageName = systemImageName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImageName)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            
            VStack(spacing: 6) {
                Text(title)
                    .font(AppTheme.Typography.sectionTitle)
                
                Text(message)
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle, let action {
                Button(actionTitle) {
                    action()
                }
                .font(AppTheme.Typography.button)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
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

#Preview("No Action") {
    EmptyStateView(
        systemImageName: "magnifyingglass",
        title: "No matching tasks",
        message: "Try changing your search text or filters."
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("With Action") {
    EmptyStateView(
        systemImageName: "tray",
        title: "No tasks yet",
        message: "Tap the button below to create your first task.",
        actionTitle: "Create Task",
        action: {}
    )
    .padding()
    .background(AppTheme.background)
}
