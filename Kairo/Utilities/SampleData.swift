//
//  SampleData.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import Foundation
import UIKit

/// Provides sample data for previews and development.
enum SampleData {
    // MARK: - Tasks
    
    static var tasks: [TaskItem] {
        [
            TaskItem(
                title: "Finish SwiftData model",
                taskDescription: "Review TaskItem, priority, category and statistics.",
                dueDate: .now,
                priority: .high,
                category: .work
            ),
            TaskItem(
                title: "Buy groceries",
                taskDescription: "Rice, milk, eggs, vegetables.",
                dueDate: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now,
                priority: .medium,
                category: .personal
            ),
            TaskItem(
                title: "Go for a walk with my family",
                taskDescription: nil,
                dueDate: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now,
                priority: .low,
                category: .health
            ),
            TaskItem(
                title: "Prepare books for B2 German Course",
                taskDescription: "Plan the German course and buy the books I need.",
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
                priority: .medium,
                category: .study,
                isCompleted: true,
                completedAt: .now
            )
        ]
    }
    
    // MARK: - Journal Photo Preview Fixtures

    @MainActor
    static var journalEntryWithPhotos: JournalEntry {
        let entry = JournalEntry(
            title: "A weekend worth remembering",
            bodyText: """
            A sunny afternoon, a peaceful walk,
            and a few favorite moments captured in photos.
            """
        )

        let samples: [(size: CGSize, color: UIColor, title: String)] = [
            (
                CGSize(width: 1200, height: 800),
                .systemTeal,
                "1 · Landscape"
            ),
            (
                CGSize(width: 800, height: 1200),
                .systemOrange,
                "2 · Portrait"
            ),
            (
                CGSize(width: 1000, height: 1000),
                .systemIndigo,
                "3 · Square"
            )
        ]

        for (position, sample) in samples.enumerated() {
            let image = makeJournalPreviewImage(
                size: sample.size,
                color: sample.color,
                title: sample.title
            )

            let thumbnail = makeJournalPreviewThumbnail(
                from: image
            )

            guard let imageData = image.jpegData(
                compressionQuality: 0.8
            ),
            let thumbnailData = thumbnail.jpegData(
                compressionQuality: 0.8
            ) else {
                continue
            }

            let photo = JournalPhoto(
                position: position,
                imageData: imageData,
                thumbnailData: thumbnailData,
                entry: entry
            )

            entry.photos.append(photo)
        }

        return entry
    }

    // MARK: - Preview Image Rendering

    @MainActor
    private static func makeJournalPreviewImage(
        size: CGSize,
        color: UIColor,
        title: String
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(
            size: size,
            format: format
        )

        return renderer.image { context in
            let bounds = CGRect(
                origin: .zero,
                size: size
            )

            color.setFill()
            context.fill(bounds)

            let border = bounds.insetBy(
                dx: 32,
                dy: 32
            )

            context.cgContext.setStrokeColor(
                UIColor.white.withAlphaComponent(0.8).cgColor
            )
            context.cgContext.setLineWidth(8)
            context.cgContext.stroke(border)

            let fontSize = min(size.width, size.height) * 0.07

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(
                    ofSize: fontSize,
                    weight: .bold
                ),
                .foregroundColor: UIColor.white
            ]

            let text = title as NSString
            let textSize = text.size(withAttributes: attributes)

            let textOrigin = CGPoint(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2
            )

            text.draw(
                at: textOrigin,
                withAttributes: attributes
            )
        }
    }

    @MainActor
    private static func makeJournalPreviewThumbnail(
        from image: UIImage
    ) -> UIImage {
        let maximumPixelSize: CGFloat = 400

        let ratio = min(
            1,
            maximumPixelSize / max(
                image.size.width,
                image.size.height
            )
        )

        let thumbnailSize = CGSize(
            width: (image.size.width * ratio).rounded(),
            height: (image.size.height * ratio).rounded()
        )

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(
            size: thumbnailSize,
            format: format
        )

        return renderer.image { _ in
            image.draw(
                in: CGRect(
                    origin: .zero,
                    size: thumbnailSize
                )
            )
        }
    }
    
    // MARK: - Journal Entries
    
    static var journalEntries: [JournalEntry] {
        let calendar = Calendar.current
        let now = Date.now
        
        return [
            JournalEntry(
                title: "A productive day",
                bodyText: """
                    Today I spent some time learning Swift and German.
                    I finally understood a few things that had been confusing me before.
                    There is still a lot to learn, but the project is moving forward.
                    """,
                entryDate: now,
                createdAt: now,
                updatedAt: now
            ),
            
            JournalEntry(
                title: "Evening walk",
                bodyText: """
                    We went for a walk in the evening. The weather was calm, and it was nice.
                    """,
                entryDate: now,
                createdAt: calendar.date(
                    byAdding: .hour,
                    value: -2,
                    to: now
                ) ?? now,
                updatedAt: calendar.date(
                    byAdding: .hour,
                    value: -2,
                    to: now
                ) ?? now
            ),
            
            JournalEntry(
                title: "Yesterday",
                bodyText: """
                    Yesterday was a quieter day. I studied a little, rested, and slept well.
                    """,
                entryDate: calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: now
                ) ?? now,
                createdAt: calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: now
                ) ?? now,
                updatedAt: calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: now
                ) ?? now
            )
        ]
    }
}
