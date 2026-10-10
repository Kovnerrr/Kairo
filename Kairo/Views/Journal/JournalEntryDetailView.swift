//
//  JournalEntryDetailView.swift
//  Kairo
//
//  Created by Andrii Kovner on 16.09.26.
//

import SwiftUI
import SwiftData

struct JournalEntryDetailView: View {
    // MARK: - Properties
    
    let entry: JournalEntry
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var isEditSheetPresented = false
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(entry.title)
                        .font(AppTheme.Typography.sectionTitle)
                        .foregroundStyle(.primary)
                    
                    Text(
                        entry.entryDate,
                        format: .dateTime
                            .day()
                            .month(.wide)
                            .year()
                    )
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
                }
                
                Divider()
                
                Text(entry.bodyText)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.primary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                    .textSelection(.enabled)
            }
            .padding()
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    isEditSheetPresented = true
                }
            }
        }
        .sheet(isPresented: $isEditSheetPresented) {
            JournalEntryFormView(
                formData: JournalEntryFormData(entry: entry),
                navigationTitle: "Edit Entry"
            ) { formData in
                try updateEntry(from: formData)
            }
        }
    }
    
    // MARK: - Actions
    
    private func updateEntry(from formData: JournalEntryFormData) throws {
        let previousTitle = entry.title
        let previousBodyText = entry.bodyText
        let previousEntryDate = entry.entryDate
        let previousUpdatedAt = entry.updatedAt
        
        entry.title = formData.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        entry.bodyText = formData.bodyText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        entry.entryDate = formData.entryDate
        entry.updatedAt = .now
        
        do {
            try modelContext.save()
            isEditSheetPresented = false
        } catch {
            entry.title = previousTitle
            entry.bodyText = previousBodyText
            entry.entryDate = previousEntryDate
            entry.updatedAt = previousUpdatedAt
            
            throw error
        }
    }
}

// MARK: - Previews

#Preview("Entry") {
    let entry = SampleData.journalEntries[0]
    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: [entry]
    )

    return NavigationStack {
        JournalEntryDetailView(entry: entry)
    }
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}
