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

struct JournalEntryFormView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    
    @State private var formData: JournalEntryFormData
    @State private var saveErrorMessage: String?
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var isImportingPhotos = false
    @State private var photoImportError: String?
    @State private var importTask: Task<Void, Never>?
    @State private var importSessionID = UUID()
    
    // MARK: - Configuration
    
    private let maxPhotoCount = 5
    
    // MARK: - Properties
    
    let navigationTitle: String
    let onSave: (JournalEntryFormData) throws -> Void
    
    // MARK: - Computed Properties
    private var remainingPhotoSlots: Int {
        max(0, maxPhotoCount - formData.photos.count)
    }
    
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
                            .disabled(isImportingPhotos)
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancelImport()
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
                    .disabled(!formData.isValid || isImportingPhotos)
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
        .onDisappear {
            cancelImport()
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
            .disabled(isImportingPhotos)
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

