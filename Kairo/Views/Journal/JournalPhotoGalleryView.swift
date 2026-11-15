//
//  JournalPhotoGalleryView.swift
//  Kairo
//
//  Created by Andrii Kovner on 12.11.26.
//

import SwiftUI
import SwiftData

struct JournalPhotoGalleryView: View {
    // MARK: - Data
    
    let entries: [JournalEntry]
    let onOpenEntry: (JournalEntry) -> Void
    
    // MARK: - State
    @State private var selectedPhoto: JournalPhoto?
    @State private var pendingEntry: JournalEntry?
    
    // MARK: - Layout
    
    private let columns = [
        GridItem(
            .adaptive(minimum: 100),
            spacing: 8
        )
    ]
    
    // MARK: - Computed Properties
    
    private var sortedEntries: [JournalEntry] {
        entries.sorted { first, second in
            if first.entryDate != second.entryDate {
                return first.entryDate > second.entryDate
            }
            
            if first.createdAt != second.createdAt {
                return first.createdAt > second.createdAt
            }
            
            return first.id.uuidString < second.id.uuidString
        }
    }
    
    private var photos: [JournalPhoto] {
        sortedEntries.flatMap { entry in
            entry.photos.sorted {first, second in
                if first.position != second.position {
                    return first.position < second.position
                }
                return first.id.uuidString < second.id.uuidString
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        let galleryPhotos = photos
        
        Group {
            if galleryPhotos.isEmpty {
                EmptyStateView(
                    systemImageName: "photo.on.rectangle.angled",
                    title: "No Photos",
                    message: "Photos from your journal entries will appear here"
                )
                .padding(.horizontal)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: columns,
                        spacing: 8
                    ) {
                        ForEach(
                            Array(galleryPhotos.enumerated()),
                            id: \.element.id
                        ) { index, photo in
                            Button {
                                selectedPhoto = photo
                            } label: {
                                JournalPhotoGridCell(
                                    photo: photo
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                Text(
                                    "Photo \(index + 1) of \(galleryPhotos.count), \(photo.entry?.title ?? "Journal entry")"
                                )
                            )
                            .accessibilityHint(
                                "Opens the photo full screen"
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .fullScreenCover(item: $selectedPhoto, onDismiss: openPendingEntry) { photo in
            JournalPhotoViewer(
                photos: galleryPhotos,
                selectedPhotoID: photo.id,
                onOpenEntry: { entry in
                    pendingEntry = entry
                    selectedPhoto = nil
                }
            )
        }
    }
    
    // MARK: - Actions
    
    private func openPendingEntry() {
        guard let entry = pendingEntry else {
            return
        }
        
        pendingEntry = nil
        onOpenEntry(entry)
    }
}

// MARK: - Previews

#Preview("Empty Gallery") {
    JournalPhotoGalleryView(
        entries: [],
        onOpenEntry: { _ in }
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}

#Preview("Photo Gallery") {
    let entry = SampleData.journalEntryWithPhotos
    let entries = [entry] + SampleData.journalEntries

    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: entries
    )

    JournalPhotoGalleryView(
        entries: entries,
        onOpenEntry: { _ in }
    )
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
}

#Preview("Dark Mode") {
    let entry = SampleData.journalEntryWithPhotos
    let entries = [entry] + SampleData.journalEntries

    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: entries
    )

    JournalPhotoGalleryView(
        entries: entries,
        onOpenEntry: { _ in }
    )
    .modelContainer(container)
    .font(AppTheme.Typography.body)
    .tint(AppTheme.accent)
    .preferredColorScheme(.dark)
}
