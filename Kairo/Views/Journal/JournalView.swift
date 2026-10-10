//
//  JournalView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI
import SwiftData

struct JournalView: View {
    // MARK: - Data
    
    @Environment(\.modelContext) private var modelContext
    
    @Query(
        sort: \JournalEntry.createdAt,
        order: .reverse
    )
    private var entries: [JournalEntry]
    
    // MARK: - State
    
    @State private var isCreateSheetPresented = false
    @State private var entryToDelete: JournalEntry?
    @State private var deleteErrorMessage: String?
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    EmptyStateView(
                        systemImageName: "book.closed",
                        title: "No Journal Entries",
                        message: "Write about your day or anything you want to remember"
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            NavigationLink {
                                JournalEntryDetailView(
                                    entry: entry
                                )
                            } label: {
                                JournalEntryCardView(
                                    entry: entry
                                )
                            }
                            .swipeActions(
                                edge: .trailing,
                                allowsFullSwipe: false
                            ) {
                                Button(role: .destructive) {
                                    entryToDelete = entry
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreateSheetPresented = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add journal entry")
                }
            }
            .sheet(isPresented: $isCreateSheetPresented) {
                JournalEntryFormView(
                    navigationTitle: "New Entry"
                ) { formData in
                    try createEntry(from: formData)
                }
            }
            .alert(
                "Delete Journal Entry?",
                isPresented: Binding(
                    get: {
                        entryToDelete != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            entryToDelete = nil
                        }
                    }
                ),
                presenting: entryToDelete
            ) { entry in
                Button("Delete", role: .destructive) {
                    deleteEntry(entry)
                }

                Button("Cancel", role: .cancel) { }
            } message: { entry in
                Text(
                    "Delete “\(entry.title)”? This action cannot be undone."
                )
            }
            
            .alert(
                "Couldn't Delete Entry",
                isPresented: Binding(
                    get: {
                        deleteErrorMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            deleteErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteErrorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    // MARK: - Actions
    
    private func createEntry(from formData: JournalEntryFormData) throws {
        let now = Date.now

        let entry = JournalEntry(
            title: formData.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            bodyText: formData.bodyText.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            entryDate: formData.entryDate,
            createdAt: now,
            updatedAt: now
        )

        modelContext.insert(entry)

        do {
            try modelContext.save()
            isCreateSheetPresented = false
        } catch {
            modelContext.delete(entry)
            throw error
        }
    }
    
    @MainActor
    private func deleteEntry(_ entry: JournalEntry) {
        defer {
            entryToDelete = nil
        }
        
        // Save existing changes before starting the deletion.
        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            deleteErrorMessage = error.localizedDescription
            return
        }
        
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
        } catch {
            // Only the deletion is pending after the successful pre-save.
            modelContext.rollback()
            deleteErrorMessage = error.localizedDescription
        }
    }
}

// MARK: - Previews

#Preview("Entries") {
    JournalView()
        .modelContainer(PreviewContainer.container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Empty") {
    JournalView()
        .modelContainer(
            PreviewContainer.make(
                tasks: [],
                journalEntries: []
            )
        )
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}
