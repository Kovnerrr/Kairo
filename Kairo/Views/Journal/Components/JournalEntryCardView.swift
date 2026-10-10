//
//  JournalEntryCardView.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.09.26.
//

import SwiftUI

struct JournalEntryCardView: View {
    // MARK: - Properties
    
    let entry: JournalEntry
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            Text(
                entry.entryDate,
                format: .dateTime
                    .day()
                    .month(.abbreviated)
                    .year()
            )
            .font(AppTheme.Typography.secondary)
            .foregroundStyle(.secondary)
            
            Text(entry.bodyText)
                .font(AppTheme.Typography.body)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(AppTheme.border, lineWidth: 1)
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

#Preview("Entry") {
    JournalEntryCardView(
        entry: SampleData.journalEntries[0]
    )
    .padding()
    .background(AppTheme.background)
}

#Preview("Long text / Large type") {
    JournalEntryCardView(
        entry: JournalEntry(
            title: "A long day of learning, small discoveries, and plans for tomorrow",
            bodyText: """
                Today I worked on Kairo and learned more about SwiftUI and SwiftData.
                Some parts took longer than expected, but each small step helped me understand the project better.
                Tomorrow I want to continue calmly, review what I have learned, and make time for a walk.
                """
        )
    )
    .padding()
    .background(AppTheme.background)
    .dynamicTypeSize(.accessibility2)
}
