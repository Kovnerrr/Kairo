//
//  JournalEntryDetailView.swift
//  Kairo
//
//  Created by Andrii Kovner on 16.09.26.
//

import SwiftUI
import SwiftData
import QuickLook

struct JournalEntryDetailView: View {
    // MARK: - Properties
    
    let entry: JournalEntry
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var isEditSheetPresented = false
    @State private var selectedPhotoID: SelectedJournalPhoto?
    @State private var fileStorage: JournalFileStorage
    @State private var fileSessionID: UUID?
    @State private var selectedDocumentURL: URL?
    @State private var documentPreviewError: String?
    
    // MARK: - Initialization

    init(
        entry: JournalEntry,
        fileStorage: JournalFileStorage = JournalFileStorage()
    ) {
        self.entry = entry
        _fileStorage = State(initialValue: fileStorage)
    }
    
    // MARK: - Computed Properties
    
    private var sortedPhotos: [JournalPhoto] {
        entry.photos.sorted {
            $0.position < $1.position
        }
    }
    
    private var sortedFiles: [JournalFile] {
        entry.files.sorted {
            $0.position < $1.position
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()
            
            AnimatedAppBackground()
                .ignoresSafeArea()
                .accessibilityHidden(true)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.title)
                            .font(AppTheme.Typography.detailTitle)
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
                    
                    if !sortedPhotos.isEmpty {
                        ScrollView(.horizontal) {
                            HStack(spacing: 12) {
                                ForEach(
                                    Array(sortedPhotos.enumerated()),
                                    id: \.element.id
                                ) { index, photo in
                                    Button {
                                        selectedPhotoID = SelectedJournalPhoto(
                                            id: photo.id
                                        )
                                    } label: {
                                        Group {
                                            if let image = UIImage(
                                                data: photo.thumbnailData
                                            ) {
                                                Image(uiImage: image)
                                                    .resizable()
                                                    .scaledToFill()
                                            } else {
                                                ZStack {
                                                    AppTheme.surface
                                                    
                                                    Image(
                                                        systemName: "photo.badge.exclamationmark"
                                                    )
                                                    .font(.title)
                                                    .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                        .frame(width: 160, height: 160)
                                        .clipped()
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 12)
                                        )
                                        .contentShape(
                                            RoundedRectangle(cornerRadius: 12)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(
                                        "Open photo \(index + 1) of \(entry.photos.count)"
                                    )
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                    }
                    
                    // MARK: Documents
                    
                    if !sortedFiles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            Text("Documents")
                                .font(.headline)
                            
                            ForEach(sortedFiles, id: \.id) { file in
                                Button {
                                    openDocument(file)
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "doc.text")
                                            .foregroundStyle(AppTheme.accent)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(file.displayName)
                                                .lineLimit(2)
                                            
                                            Text(
                                                ByteCountFormatter.string(
                                                    fromByteCount: file.fileSize,
                                                    countStyle: .file
                                                )
                                            )
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(minHeight: 44)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Open document \(file.displayName)")
                            }
                        }
                    }
                    
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
        .sheet(
            isPresented: $isEditSheetPresented,
            onDismiss: closeFileSession
        ) {
            JournalEntryFormView(
                formData: JournalEntryFormData(entry: entry),
                navigationTitle: "Edit Entry",
                fileStorage: fileStorage,
                fileSessionID: $fileSessionID,
                isPresented: $isEditSheetPresented
            ) { formData in
                try await updateEntry(from: formData)
            }
        }
        
        .fullScreenCover(item: $selectedPhotoID) { selection in
            JournalPhotoViewer(
                photos: sortedPhotos,
                selectedPhotoID: selection.id
            )
        }
        
        .quickLookPreview($selectedDocumentURL)
        .alert(
            "Couldn't Open Document",
            isPresented: Binding(
                get: {
                    documentPreviewError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        documentPreviewError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                documentPreviewError = nil
            }
        } message: {
            Text(
                documentPreviewError ?? "An unknown error occurred."
            )
        }
    }
    
    // MARK: - Actions
    
    private func openDocument(_ file: JournalFile) {
        Task { @MainActor in
            do {
                let url = try await fileStorage.fileURL(
                    storedFileName: file.storedFileName
                )

                guard FileManager.default.fileExists(atPath: url.path) else {
                    documentPreviewError = "The document could not be found."
                    return
                }

                selectedDocumentURL = url
            } catch {
                documentPreviewError = error.localizedDescription
            }
        }
    }
    
    private func updateEntry(
        from formData: JournalEntryFormData
    ) async throws {
        guard formData.isValid else {
            throw JournalEntrySaveError.invalidForm
        }

        guard entry.modelContext != nil,
              !entry.isDeleted else {
            throw JournalEntrySaveError.entryUnavailable
        }

        let entryID = entry.id

        let preparedFiles = try await fileStorage.preparePermanentCopies(
            from: formData.files
        )

        var removedFileNames: [String] = []

        do {
            try Task.checkCancellation()

            guard isEditSheetPresented else {
                throw CancellationError()
            }

            // No await between this pre-save and the final SwiftData save.
            if modelContext.hasChanges {
                try modelContext.save()
            }

            let descriptor = FetchDescriptor<JournalEntry>(
                predicate: #Predicate { candidate in
                    candidate.id == entryID
                }
            )

            guard let currentEntry = try modelContext.fetch(descriptor).first,
                  !currentEntry.isDeleted else {
                throw JournalEntrySaveError.entryUnavailable
            }

            let existingPhotos = Array(currentEntry.photos)
            let existingFiles = Array(currentEntry.files)

            let retainedPhotoIDs = Set(formData.photos.map(\.id))
            let retainedFileIDs = Set(formData.files.map(\.id))

            let removedFiles = existingFiles.filter {
                !retainedFileIDs.contains($0.id)
            }

            // Keep plain values, not deleted SwiftData objects.
            removedFileNames = removedFiles.map(\.storedFileName)

            do {
                currentEntry.title = formData.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                currentEntry.bodyText = formData.bodyText.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                currentEntry.entryDate = formData.entryDate
                currentEntry.updatedAt = .now

                for photo in existingPhotos {
                    if !retainedPhotoIDs.contains(photo.id) {
                        modelContext.delete(photo)
                    }
                }

                for (position, draft) in formData.photos.enumerated() {
                    switch draft.source {
                    case .existing:
                        guard let photo = existingPhotos.first(
                            where: { $0.id == draft.id }
                        ) else {
                            throw JournalEntrySaveError.attachmentUnavailable
                        }

                        photo.position = position

                    case .imported(let imageData):
                        let photo = JournalPhoto(
                            id: draft.id,
                            position: position,
                            imageData: imageData,
                            thumbnailData: draft.thumbnailData,
                            entry: currentEntry
                        )

                        modelContext.insert(photo)
                    }
                }

                for file in removedFiles {
                    modelContext.delete(file)
                }

                for (position, draft) in formData.files.enumerated() {
                    switch draft {
                    case .existing(let id, _, _, _, _):
                        guard let file = existingFiles.first(
                            where: { $0.id == id }
                        ) else {
                            throw JournalEntrySaveError.attachmentUnavailable
                        }

                        file.position = position

                    case .imported(let importedFile):
                        guard let prepared = preparedFiles.first(
                            where: { $0.id == importedFile.id }
                        ) else {
                            throw JournalEntrySaveError.attachmentUnavailable
                        }

                        let file = JournalFile(
                            id: prepared.id,
                            displayName: prepared.displayName,
                            storedFileName: prepared.storedFileName,
                            contentTypeIdentifier: prepared.contentTypeIdentifier,
                            fileSize: prepared.fileSize,
                            position: position,
                            entry: currentEntry
                        )

                        modelContext.insert(file)
                    }
                }

                try modelContext.save()

            } catch {
                modelContext.rollback()
                throw error
            }

        } catch {
            await fileStorage.removePermanentFiles(
                storedFileNames: preparedFiles.map(\.storedFileName)
            )

            throw error
        }

        // SwiftData has committed successfully.
        await fileStorage.removePermanentFiles(
            storedFileNames: removedFileNames
        )

        isEditSheetPresented = false
    }
    
    private func closeFileSession() {
        guard let sessionID = fileSessionID else {
            return
        }

        fileSessionID = nil

        Task {
            await fileStorage.closeSession(id: sessionID)
        }
    }
}

// MARK: - Photo Selection

private struct SelectedJournalPhoto: Identifiable {
    let id: UUID
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

#Preview("Entry · With Photos") {
    let entry = SampleData.journalEntryWithPhotos
    
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

#Preview("Journal Entry - Long Text / Large Type") {
    let entry = JournalEntry(
        title: "A day of learning SwiftUI, reviewing Kairo, and planning the next steps",
        bodyText: """
        Today I reviewed the calendar and the task cards.
        I want the screens to feel consistent and remain easy to read.
        
        Tomorrow I will continue learning and review the changes carefully.
        """
    )
    
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
    .dynamicTypeSize(.accessibility3)
    .preferredColorScheme(.dark)
}
