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
    
    @State private var displayMode: JournalDisplayMode
    @State private var entryToOpen: JournalEntry?
    @State private var isCreateSheetPresented = false
    @State private var entryToDelete: JournalEntry?
    @State private var deleteErrorMessage: String?
    @State private var fileStorage: JournalFileStorage
    @State private var fileSessionID: UUID?
    
    // MARK: - Initialization

    init(
        fileStorage: JournalFileStorage = JournalFileStorage(),
        displayMode: JournalDisplayMode = .entries
    ) {
        _fileStorage = State(initialValue: fileStorage)
        _displayMode = State(initialValue: displayMode)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                AnimatedAppBackground()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                
                VStack(spacing: 0) {
                    displayModePicker
                    
                    Group {
                        switch displayMode {
                        case .entries:
                            entriesContent
                            
                        case .photos:
                            photosContent
                        }
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                }
            }
            .navigationTitle("Journal")
            .navigationDestination(item: $entryToOpen) { entry in
                JournalEntryDetailView(
                    entry: entry
                )
            }
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
            .sheet(
                isPresented: $isCreateSheetPresented,
                onDismiss: closeFileSession
            ) {
                JournalEntryFormView(
                    navigationTitle: "New Entry",
                    fileStorage: fileStorage,
                    fileSessionID: $fileSessionID,
                    isPresented: $isCreateSheetPresented
                ) { formData in
                    try await createEntry(from: formData)
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
    
    // MARK: - Components
    
    private var displayModePicker: some View {
        Picker("Journal display mode", selection: $displayMode) {
            ForEach(JournalDisplayMode.allCases) { mode in
                Text(mode.title)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private var entriesContent: some View {
        if entries.isEmpty {
            EmptyStateView(
                systemImageName: "book.closed",
                title: "No Journal Entries",
                message: "Write about your day or anything you want to remember"
            )
            .padding(.horizontal)
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
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }
    
    private var photosContent: some View {
        JournalPhotoGalleryView(
            entries: entries,
            onOpenEntry: { entry in
                entryToOpen = entry
            }
        )
    }
    
    // MARK: - Actions
    
    private func createEntry(
        from formData: JournalEntryFormData
    ) async throws {
        guard formData.isValid else {
            throw JournalEntrySaveError.invalidForm
        }

        let preparedFiles = try await fileStorage.preparePermanentCopies(
            from: formData.files
        )

        do {
            try Task.checkCancellation()

            guard isCreateSheetPresented else {
                throw CancellationError()
            }

            // No await between this pre-save and the final SwiftData save.
            if modelContext.hasChanges {
                try modelContext.save()
            }

            do {
                let now = Date.now

                let newEntry = JournalEntry(
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

                for (position, draft) in formData.photos.enumerated() {
                    guard case let .imported(imageData) = draft.source else {
                        throw JournalEntrySaveError.invalidForm
                    }

                    let photo = JournalPhoto(
                        id: draft.id,
                        position: position,
                        imageData: imageData,
                        thumbnailData: draft.thumbnailData,
                        entry: newEntry
                    )

                    newEntry.photos.append(photo)
                }

                for (position, draft) in formData.files.enumerated() {
                    guard case let .imported(importedFile) = draft,
                          let prepared = preparedFiles.first(
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
                        entry: newEntry
                    )

                    newEntry.files.append(file)
                }

                modelContext.insert(newEntry)
                try modelContext.save()

            } catch {
                // Only changes made after the successful pre-save are pending.
                modelContext.rollback()
                throw error
            }

        } catch {
            await fileStorage.removePermanentFiles(
                storedFileNames: preparedFiles.map(\.storedFileName)
            )

            throw error
        }

        isCreateSheetPresented = false
    }
    
    @MainActor
    private func deleteEntry(_ entry: JournalEntry) {
        defer {
            entryToDelete = nil
        }

        guard entry.modelContext != nil,
              !entry.isDeleted else {
            deleteErrorMessage =
                JournalEntrySaveError.entryUnavailable.localizedDescription
            return
        }

        do {
            if modelContext.hasChanges {
                try modelContext.save()
            }
        } catch {
            deleteErrorMessage = error.localizedDescription
            return
        }

        // Read filenames before deleting the models.
        let storedFileNames = entry.files.map(\.storedFileName)

        modelContext.delete(entry)

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            deleteErrorMessage = error.localizedDescription
            return
        }

        // The database deletion has already succeeded.
        Task {
            await fileStorage.removePermanentFiles(
                storedFileNames: storedFileNames
            )
        }
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

#Preview("Journal - Photos Across Entries") {
    let now = Date.now
    let yesterday = Calendar.current.date(
        byAdding: .day,
        value: -1,
        to: now
    ) ?? now

    let firstEntry = SampleData.journalEntryWithPhotos
    firstEntry.title = "Today — Entry A"
    firstEntry.entryDate = now
    firstEntry.createdAt = yesterday

    let secondEntry = SampleData.journalEntryWithPhotos
    secondEntry.title = "Yesterday — Entry B"
    secondEntry.entryDate = yesterday
    secondEntry.createdAt = now

    return JournalView(displayMode: .photos)
        .modelContainer(
            PreviewContainer.make(
                tasks: [],
                journalEntries: [
                    secondEntry,
                    firstEntry
                ]
            )
        )
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Journal - Empty Photos") {
    JournalView(displayMode: .photos)
        .modelContainer(
            PreviewContainer.make(
                tasks: [],
                journalEntries: [],
                moods: []
            )
        )
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Journal - Photos Dark Mode") {
    let entry = SampleData.journalEntryWithPhotos

    JournalView(displayMode: .photos)
        .modelContainer(
            PreviewContainer.make(
                tasks: [],
                journalEntries: [entry]
            )
        )
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
}
