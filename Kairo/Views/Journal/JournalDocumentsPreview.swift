//
//  JournalDocumentsPreview.swift
//  Kairo
//
//  Created by Andrii Kovner on 11.11.26.
//

import SwiftUI
import SwiftData

#if DEBUG

private enum JournalDocumentPreviewMode {
    case detail
    case form
    case importedDraft
    case missingFile

    var showsForm: Bool {
        switch self {
        case .form, .importedDraft:
            true

        case .detail, .missingFile:
            false
        }
    }
}

private struct JournalDocumentsPreview: View {
    let mode: JournalDocumentPreviewMode

    @State private var data: JournalDocumentPreviewData?
    @State private var errorMessage: String?
    @State private var isFormPresented = false
    @State private var fileSessionID: UUID?

    var body: some View {
        ZStack {
            if let data {
                if mode.showsForm {
                    Text("Journal form preview")
                } else {
                    NavigationStack {
                        JournalEntryDetailView(
                            entry: data.entry,
                            fileStorage: data.fileStorage
                        )
                    }
                    .modelContainer(data.container)
                }

            } else if let errorMessage {
                Text(errorMessage)
                    .padding()

            } else {
                ProgressView("Preparing preview…")
            }
        }
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
        .sheet(
            isPresented: $isFormPresented,
            onDismiss: closeFileSession
        ) {
            if let data {
                JournalEntryFormView(
                    formData: data.formData,
                    navigationTitle: "Edit Entry",
                    fileStorage: data.fileStorage,
                    fileSessionID: $fileSessionID,
                    isPresented: $isFormPresented
                ) { _ in
                    // This preview checks the form, not persistence.
                    isFormPresented = false
                }
                .modelContainer(data.container)
                .font(AppTheme.Typography.body)
                .tint(AppTheme.accent)
            }
        }
        .task {
            guard data == nil else {
                return
            }

            do {
                let prepared = try await SampleData.makeJournalDocumentPreview(
                    includeMissingFile: mode == .missingFile,
                    includeImportedDraft: mode == .importedDraft
                )

                guard !Task.isCancelled else {
                    if let sessionID = prepared.fileSessionID {
                        await prepared.fileStorage.closeSession(
                            id: sessionID
                        )
                    }

                    return
                }

                data = prepared
                fileSessionID = prepared.fileSessionID
                isFormPresented = mode.showsForm

            } catch is CancellationError {
                return

            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func closeFileSession() {
        guard let sessionID = fileSessionID,
              let data else {
            return
        }

        fileSessionID = nil

        Task {
            await data.fileStorage.closeSession(id: sessionID)
        }
    }
}

// MARK: - Previews

#Preview("Journal · Photos and Documents") {
    JournalDocumentsPreview(mode: .detail)
}

#Preview("Journal Form · Existing Documents") {
    JournalDocumentsPreview(mode: .form)
}

#Preview("Journal Form · Imported Draft") {
    JournalDocumentsPreview(mode: .importedDraft)
}

#Preview("Journal · Missing Document") {
    JournalDocumentsPreview(mode: .missingFile)
}

#Preview("Journal · Documents · Large Type") {
    JournalDocumentsPreview(mode: .detail)
        .dynamicTypeSize(.accessibility3)
}

#endif
