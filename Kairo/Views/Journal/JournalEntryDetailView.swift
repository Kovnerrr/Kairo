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
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - State
    
    @State private var isEditSheetPresented = false
    @State private var selectedPhotoID: SelectedJournalPhoto?
    
    // MARK: - Computed Properties

    private var sortedPhotos: [JournalPhoto] {
        entry.photos.sorted {
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
        .sheet(isPresented: $isEditSheetPresented) {
            JournalEntryFormView(
                formData: JournalEntryFormData(entry: entry),
                navigationTitle: "Edit Entry"
            ) { formData in
                try updateEntry(from: formData)
            }
        }
        
        .fullScreenCover(item: $selectedPhotoID) { selection in
            JournalPhotoViewer(
                photos: sortedPhotos,
                selectedPhotoID: selection.id
            )
        }
    }
    
    // MARK: - Actions
    
    private func updateEntry(from formData: JournalEntryFormData) throws {
        
        // Save unrelated pending changes before editing.
        if modelContext.hasChanges {
            try modelContext.save()
        }
        
        let retainedIDs = Set(formData.photos.map(\.id))
        let existingPhotos = Array(entry.photos)

        // Update entry properties.
        entry.title = formData.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        entry.bodyText = formData.bodyText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        entry.entryDate = formData.entryDate
        entry.updatedAt = .now

        // Delete photos removed from the draft.
        for photo in existingPhotos {
            if !retainedIDs.contains(photo.id) {
                modelContext.delete(photo)
            }
        }

        // Update existing photos and add imported photos.
        for (position, draft) in formData.photos.enumerated() {
            switch draft.source {
            case .existing:
                if let photo = existingPhotos.first(
                    where: { $0.id == draft.id }
                ) {
                    photo.position = position
                }
                
            case .imported(let imageData):
                let photo = JournalPhoto(
                    id: draft.id,
                    position: position,
                    imageData: imageData,
                    thumbnailData: draft.thumbnailData,
                    entry: entry
                )
                modelContext.insert(photo)
            }
        }
        
        do {
            try modelContext.save()
            isEditSheetPresented = false
        } catch {
            modelContext.rollback()
            throw error
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
