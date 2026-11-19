//
//  OnThisDayCardView.swift
//  Kairo
//
//  Created by Andrii Kovner on 18.11.26.
//

import SwiftUI
import UIKit

struct OnThisDayCardView: View {
    
    // MARK: - Data
    
    let entry: JournalEntry
    let yearsAgo: Int
    
    // MARK: - Computed Properties
    
    private var firstPhoto: JournalPhoto? {
        entry.photos.min { first, second in
            if first.position != second.position {
                return first.position < second.position
            }
            
            return first.id.uuidString < second.id.uuidString
        }
    }
    
    private var formattedDate: String {
        entry.entryDate.formatted(
            .dateTime
                .month(.wide)
                .day()
                .year()
        )
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Memory age
            Label {
                Text(
                    yearsAgo == 1
                    ? "1 year ago"
                    : "\(yearsAgo) years ago"
                )
            } icon: {
                Image(systemName: "clock.arrow.circlepath")
            }
            .font(AppTheme.Typography.secondary.weight(.semibold))
            .foregroundStyle(AppTheme.accent)
            
            // Entry title
            Text(entry.title)
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.primary)
                .lineLimit(2)
            
            // Entry date
            Text(formattedDate)
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
            
            // Optional photo
            if let firstPhoto {
                photoContent(firstPhoto)
            }
            
            // Optional entry text
            if !entry.bodyText.isEmpty {
                Text(entry.bodyText)
                    .font(AppTheme.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
    
    // MARK: - Photo
    
    private func photoContent(_ photo: JournalPhoto) -> some View {
        GeometryReader { geometry in
            if let image = UIImage(data: photo.thumbnailData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
            } else {
                Rectangle()
                    .fill(.secondary.opacity(0.12))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityHidden(true)
    }
}
