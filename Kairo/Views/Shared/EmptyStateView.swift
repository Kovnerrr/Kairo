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
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImageName)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    EmptyStateView(
        systemImageName: "tray",
        title: "No tasks yet",
        message: "Tap the plus button to create your first task"
    )
    .padding()
}
