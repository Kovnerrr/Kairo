//
//  JournalEntryFormView.swift
//  Kairo
//
//  Created by Andrii Kovner on 07.10.26.
//

import SwiftUI

struct JournalEntryFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var formData: JournalEntryFormData
    @State private var saveErrorMessage: String?
    
    // MARK: - Properties
    
    let navigationTitle: String
    let onSave: (JournalEntryFormData) throws -> Void
    
    // MARK: - Initialization
    
    init(
        formData: JournalEntryFormData = JournalEntryFormData(),
        navigationTitle: String,
        onSave: @escaping (JournalEntryFormData) throws -> Void
    ) {
        _formData = State(initialValue: formData)
        self.navigationTitle = navigationTitle
        self.onSave = onSave
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField(
                        "Title",
                        text: $formData.title
                    )
                    
                    DatePicker(
                        "Date",
                        selection: $formData.entryDate,
                        displayedComponents: .date
                    )
                }
                
                Section("Notes") {
                    TextEditor(text: $formData.bodyText)
                        .frame(minHeight: 180)
                        .accessibilityLabel("Journal entry text")
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try onSave(formData)
                        } catch {
                            saveErrorMessage = error.localizedDescription
                        }
                    }
                    .disabled(!formData.isValid)
                }
            }
        }
        .alert(
            "Couldn't Save Entry",
            isPresented: Binding(
                get: {
                    saveErrorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        saveErrorMessage = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                saveErrorMessage = nil
            }
        } message: {
            Text(saveErrorMessage ?? "An unknown error occurred.")
        }
    }
}

// MARK: - Previews

#Preview("Create") {
    JournalEntryFormView(
        navigationTitle: "New Entry"
    ) { _ in }
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Edit") {
    JournalEntryFormView(
        formData: JournalEntryFormData(
            entry: SampleData.journalEntries[0]
        ),
        navigationTitle: "Edit Entry"
    ) { _ in }
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

