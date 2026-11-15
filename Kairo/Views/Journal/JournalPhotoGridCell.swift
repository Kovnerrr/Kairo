//
//  JournalPhotoGridCell.swift
//  Kairo
//
//  Created by Andrii Kovner on 13.11.26.
//

import SwiftUI
import UIKit
import SwiftData

struct JournalPhotoGridCell: View {
    
    // MARK: - Data
    
    let photo: JournalPhoto
    
    // MARK: - Body
    
    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geometry in
                    if let image = UIImage(
                        data: photo.thumbnailData
                    ) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(
                                width: geometry.size.width,
                                height: geometry.size.height
                            )
                            .clipped()
                    } else {
                        placeholder
                    }
                }
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 12)
            )
            .accessibilityLabel("Journal photo")
    }
    
    // MARK: - Components
    
    private var placeholder: some View {
        ZStack {
            Color.secondary.opacity(0.12)
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview("Photo Grid Cell") {
    let entry = SampleData.journalEntryWithPhotos

    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: [entry]
    )

    if let photo = entry.photos.min(
        by: { $0.position < $1.position }
    ) {
        JournalPhotoGridCell(photo: photo)
            .frame(width: 120, height: 120)
            .padding()
            .modelContainer(container)
    }
}
