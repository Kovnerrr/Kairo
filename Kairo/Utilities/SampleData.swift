//
//  SampleData.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import Foundation
import UIKit
import SwiftData
import UniformTypeIdentifiers

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
    
    // MARK: - Journal Document Preview Fixtures

    @MainActor
    static func makeJournalDocumentPreview(
        includeMissingFile: Bool = false,
        includeImportedDraft: Bool = false
    ) async throws -> JournalDocumentPreviewData {
        let root = FileManager.default.temporaryDirectory
            .appending(
                path: "KairoDocumentPreviews",
                directoryHint: .isDirectory
            )
            .appending(
                path: UUID().uuidString,
                directoryHint: .isDirectory
            )

        let documentsDirectory = root.appending(
            path: "JournalFiles/Documents",
            directoryHint: .isDirectory
        )

        try FileManager.default.createDirectory(
            at: documentsDirectory,
            withIntermediateDirectories: true
        )

        let fileStorage = JournalFileStorage(
            storageRoot: root,
            temporaryRoot: root
        )

        let entry = journalEntryWithPhotos

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(
                x: 0,
                y: 0,
                width: 595,
                height: 842
            )
        )

        let pdfData = renderer.pdfData { context in
            context.beginPage()

            let text = """
            Kairo — Journal Preview

            This is a small PDF document for SwiftUI previews.
            """

            (text as NSString).draw(
                in: CGRect(
                    x: 40,
                    y: 40,
                    width: 515,
                    height: 300
                ),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 20),
                    .foregroundColor: UIColor.black
                ]
            )
        }

        let textData = Data(
            """
            Kairo Journal Preview

            A small UTF-8 text document.
            English, Українська, Русский, Deutsch.
            """.utf8
        )

        let samples: [(name: String, type: UTType, data: Data)] = [
            ("Weekend notes.pdf", .pdf, pdfData),
            ("Reflection.txt", .plainText, textData)
        ]

        var textURL: URL?

        for (position, sample) in samples.enumerated() {
            let id = UUID()
            let ext = sample.type == .pdf ? "pdf" : "txt"
            let storedFileName = id.uuidString + "." + ext

            let url = documentsDirectory.appending(
                path: storedFileName,
                directoryHint: .notDirectory
            )

            try sample.data.write(to: url, options: .atomic)

            let file = JournalFile(
                id: id,
                displayName: sample.name,
                storedFileName: storedFileName,
                contentTypeIdentifier: sample.type.identifier,
                fileSize: Int64(sample.data.count),
                position: position,
                entry: entry
            )

            entry.files.append(file)

            if sample.type == .plainText {
                textURL = url
            }
        }

        if includeMissingFile {
            let file = JournalFile(
                displayName: "Missing document.pdf",
                storedFileName: UUID().uuidString + ".pdf",
                contentTypeIdentifier: UTType.pdf.identifier,
                fileSize: 1024,
                position: entry.files.count,
                entry: entry
            )

            entry.files.append(file)
        }

        var formData = JournalEntryFormData(entry: entry)
        var sessionID: UUID?

        do {
            if includeImportedDraft {
                guard let textURL else {
                    throw JournalFileStorageError.fileUnavailable
                }

                let createdSessionID = try await fileStorage.createSession()
                sessionID = createdSessionID

                let importedFile = try await fileStorage.importFile(
                    from: .appOwned(textURL),
                    sessionID: createdSessionID
                )

                // Show one retained document and one newly imported draft.
                formData.files = Array(formData.files.prefix(1))
                formData.files.append(.imported(importedFile))
            }

            try Task.checkCancellation()

            let container = PreviewContainer.make(
                tasks: [],
                journalEntries: [entry]
            )

            return JournalDocumentPreviewData(
                entry: entry,
                formData: formData,
                container: container,
                fileStorage: fileStorage,
                fileSessionID: sessionID
            )

        } catch {
            if let sessionID {
                await fileStorage.closeSession(id: sessionID)
            }

            throw error
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

// MARK: - Journal Document Preview Data

struct JournalDocumentPreviewData {
    let entry: JournalEntry
    let formData: JournalEntryFormData
    let container: ModelContainer
    let fileStorage: JournalFileStorage
    let fileSessionID: UUID?
}
