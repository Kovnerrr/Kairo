//
//  JournalEntryFormView.swift
//  Kairo
//
//  Created by Andrii Kovner on 07.10.26.
//

import SwiftUI
import PhotosUI
import UIKit
import SwiftData
import UniformTypeIdentifiers

struct JournalEntryFormView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Presentation

    @Binding private var fileSessionID: UUID?
    @Binding private var isPresented: Bool
    
    // MARK: - State
    
    @State private var formData: JournalEntryFormData
    @State private var saveErrorMessage: String?
    @State private var isSaving = false
    @State private var isFilePickerPresented = false
    @State private var isImportingFile = false
    @State private var fileImportError: String?
    @State private var fileImportTask: Task<Void, Never>?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImportingPhotos = false
    @State private var photoImportError: String?
    @State private var importTask: Task<Void, Never>?
    @State private var importSessionID = UUID()
    
    // MARK: - Configuration
    
    private let maxPhotoCount = 5
    private let maxFileCount = 3
    
    // MARK: - Properties
    
    let navigationTitle: String
    let fileStorage: JournalFileStorage?
    let onSave: (JournalEntryFormData) async throws -> Void
    
    // MARK: - Computed Properties
    private var remainingPhotoSlots: Int {
        max(0, maxPhotoCount - formData.photos.count)
    }
    
    // MARK: - Initialization
    
    init(
        formData: JournalEntryFormData = JournalEntryFormData(),
        navigationTitle: String,
        fileStorage: JournalFileStorage? = nil,
        fileSessionID: Binding<UUID?> = .constant(nil),
        isPresented: Binding<Bool> = .constant(true),
        onSave: @escaping (JournalEntryFormData) async throws -> Void
    ) {
        _formData = State(initialValue: formData)
        _fileSessionID = fileSessionID
        _isPresented = isPresented

        self.navigationTitle = navigationTitle
        self.fileStorage = fileStorage
        self.onSave = onSave
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
                
                Form {
                    
                    // MARK: Entry Section
                    
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
                    .listRowBackground(AppTheme.surface)
                    
                    // MARK: Notes Section
                    
                    Section("Notes") {
                        TextEditor(text: $formData.bodyText)
                            .frame(minHeight: 180)
                            .accessibilityLabel("Journal entry text")
                    }
                    .listRowBackground(AppTheme.surface)
                    
                    // MARK: Photos Section
                    
                    Section("Photos") {
                        if !formData.photos.isEmpty {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12) {
                                    ForEach(
                                        Array(formData.photos.enumerated()),
                                        id: \.element.id
                                    ) { index, photo in
                                        photoThumbnail(photo, at: index)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            .scrollIndicators(.hidden)
                        }
                        
                        if remainingPhotoSlots > 0 {
                            PhotosPicker(
                                selection: $selectedPhotoItems,
                                maxSelectionCount: remainingPhotoSlots,
                                selectionBehavior: .ordered,
                                matching: .images
                            ) {
                                Label(
                                    "Add Photos",
                                    systemImage: "photo.badge.plus"
                                )
                            }
                            .disabled(isImportingPhotos || isSaving)
                        }
                        
                        if isImportingPhotos {
                            ProgressView("Importing photos...")
                        }
                        
                        Text(
                            "\(formData.photos.count) of \(maxPhotoCount) photos"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .listRowBackground(AppTheme.surface)
                    
                    // MARK: Documents Section
                    
                    Section("Documents") {
                        ForEach(formData.files) { draft in
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text")
                                    .foregroundStyle(AppTheme.accent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fileDisplayName(for: draft))
                                        .lineLimit(2)
                                    Text(
                                        ByteCountFormatter.string(
                                            fromByteCount: fileSize(for: draft),
                                            countStyle: .file
                                        )
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                
                                Button {
                                    formData.files.removeAll {
                                        $0.id == draft.id
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel(
                                    "Remove document \(fileDisplayName(for: draft))"
                                )
                            }
                        }
                        
                        if formData.files.count < maxFileCount && !isImportingFile {
                            
                            Button {
                                isFilePickerPresented = true
                            } label: {
                                Label(
                                    "Add Document",
                                    systemImage: "doc.badge.plus"
                                )
                            }
                            .disabled(fileStorage == nil)
                        }
                        
                        if isImportingFile {
                            ProgressView("Importing document...")
                        }
                        
                        Text(
                            "\(formData.files.count) of \(maxFileCount) documents"
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .listRowBackground(AppTheme.surface)
                }
                .scrollContentBackground(.hidden)
                .disabled(isSaving)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelImport()
                        fileImportTask?.cancel()
                        isPresented = false
                        dismiss()
                    }
                    .disabled(isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard !isSaving,
                              formData.isValid,
                              !isImportingPhotos,
                              !isImportingFile else {
                            return
                        }
                        
                        isSaving = true
                        
                        let snapshot = formData
                        
                        Task { @MainActor in
                            defer {
                                isSaving = false
                            }
                            
                            do {
                                try await onSave(snapshot)
                            } catch is CancellationError {
                                // The form was closed before the save could commit.
                            } catch {
                                guard isPresented else {
                                    return
                                }

                                saveErrorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(
                        !formData.isValid ||
                        isImportingPhotos ||
                        isImportingFile ||
                        isSaving
                    )
                }
            }
        }
        .fileImporter(
            isPresented: $isFilePickerPresented,
            allowedContentTypes: [.pdf, .plainText],
            allowsMultipleSelection: false
        ) { result in
            
            switch result {
                
            case .success(let urls):
                guard let url = urls.first else {
                    return
                }
                startFileImport(from: url)
                
            case .failure(let error):
                fileImportError = error.localizedDescription
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
        
        .alert(
            "Couldn't Import Document",
            isPresented: Binding(
                get: {
                    fileImportError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        fileImportError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                fileImportError = nil
            }
        } message: {
            Text(
                fileImportError ?? "An unknown error occurred."
            )
        }
        
        .alert(
            "Couldn't Import Photos",
            isPresented: Binding(
                get: {
                    photoImportError != nil
                },
                set: { isPresented in
                    if !isPresented {
                        photoImportError = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                photoImportError = nil
            }
        } message: {
            Text(
                photoImportError ?? "An unknown error occurred."
            )
        }
        .onChange(of: selectedPhotoItems) { _, newItems in
            guard !newItems.isEmpty else {
                return
            }
            
            startImport(newItems)
        }
        .interactiveDismissDisabled(isSaving || isImportingFile)
        .onChange(of: isPresented) { _, presented in
            guard !presented else {
                return
            }

            cancelImport()
            fileImportTask?.cancel()
            isFilePickerPresented = false
        }
    }
    
    // MARK: - Document Import
    
    private func startFileImport(from url: URL) {
        guard isPresented,
              !isImportingFile,
              !isSaving,
              formData.files.count < maxFileCount,
              let fileStorage else {
            return
        }

        isImportingFile = true

        fileImportTask = Task { @MainActor in
            defer {
                isImportingFile = false
                fileImportTask = nil
            }

            do {
                try Task.checkCancellation()

                guard isPresented else {
                    throw CancellationError()
                }

                let sessionID: UUID

                if let existingSessionID = fileSessionID {
                    sessionID = existingSessionID
                } else {
                    let createdSessionID = try await fileStorage.createSession()

                    guard !Task.isCancelled, isPresented else {
                        await fileStorage.closeSession(
                            id: createdSessionID
                        )

                        throw CancellationError()
                    }

                    fileSessionID = createdSessionID
                    sessionID = createdSessionID
                }

                try Task.checkCancellation()

                let importedFile = try await fileStorage.importFile(
                    from: .filesPicker(url),
                    sessionID: sessionID
                )

                try Task.checkCancellation()

                guard isPresented,
                      fileSessionID == sessionID else {
                    throw CancellationError()
                }

                guard formData.files.count < maxFileCount else {
                    return
                }

                formData.files.append(.imported(importedFile))

            } catch is CancellationError {
                return
            } catch {
                guard isPresented, !Task.isCancelled else {
                    return
                }

                fileImportError = error.localizedDescription
            }
        }
    }
    
    // MARK: - Document Metadata
    
    private func fileDisplayName(
        for draft: JournalFileDraft
    ) -> String {
        switch draft {
            
        case .existing(_, let displayName, _, _, _):
            return displayName
            
        case .imported(let file):
            return file.displayName
        }
    }
    
    private func fileSize(
        for draft: JournalFileDraft
    ) -> Int64 {
        switch draft {
            
        case .existing(_, _, _, _, let fileSize):
            return fileSize
            
        case .imported(let file):
            return file.fileSize
        }
    }
    
    // MARK: - Photo Thumbnail
    
    private func photoThumbnail(
        _ photo: JournalPhotoDraft,
        at index: Int
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if let image = UIImage(data: photo.thumbnailData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipped()
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                } else {
                    Image(systemName: "photo")
                        .frame(width: 110, height: 110)
                }
            }
            .accessibilityHidden(true)
            
            Button {
                formData.photos.removeAll {
                    $0.id == photo.id
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .white,
                        .black.opacity(0.7)
                    )
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                "Remove photo \(index + 1) of \(formData.photos.count)"
            )
            .disabled(isImportingPhotos || isSaving)
        }
    }
    
    // MARK: - Photo Import
    
    private func startImport(
        _ items: [PhotosPickerItem]
    ) {
        guard !isImportingPhotos else {
            return
        }
        
        let sessionID = UUID()
        importSessionID = sessionID
        isImportingPhotos = true
        
        importTask = Task {
            var failures = 0
            for item in items {
                if Task.isCancelled ||
                    importSessionID != sessionID {
                    break
                }
                
                if formData.photos.count >= maxPhotoCount {
                    break
                }
                
                do {
                    guard let data = try await item.loadTransferable(
                        type: Data.self
                    ) else {
                        failures += 1
                        continue
                    }
                    
                    try Task.checkCancellation()
                    let processed = try await ImageProcessingService.process(
                        data
                    )
                    
                    try Task.checkCancellation()
                    guard importSessionID == sessionID else {
                        break
                    }
                    let photo = JournalPhotoDraft(
                        id: UUID(),
                        thumbnailData: processed.thumbnailData,
                        source: .imported(
                            imageData: processed.imageData
                        )
                    )
                    formData.photos.append(photo)
                    
                } catch is CancellationError {
                    break
                } catch {
                    failures += 1
                }
            }
            
            guard importSessionID == sessionID else {
                return
            }
            
            selectedPhotoItems = []
            isImportingPhotos = false
            importTask = nil
            
            if failures > 0 {
                photoImportError =
                "Could not import \(failures) photo(s). Please try again."
            }
        }
    }
    
    // MARK: - Cancel Import
    
    private func cancelImport() {
        importSessionID = UUID()
        
        importTask?.cancel()
        importTask = nil
        
        isImportingPhotos = false
        selectedPhotoItems = []
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

#Preview("Edit · With Photos") {
    let entry = SampleData.journalEntryWithPhotos
    
    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: [entry]
    )
    
    return JournalEntryFormView(
        formData: JournalEntryFormData(entry: entry),
        navigationTitle: "Edit Entry"
    ) { _ in }
        .modelContainer(container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

