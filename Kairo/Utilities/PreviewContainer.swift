//
//  PreviewContainer.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import SwiftData

/// Creates in-memory SwiftData containers for previews.
enum PreviewContainer {
    // MARK: - Default Container

    @MainActor
    static var container: ModelContainer {
        make()
    }

    // MARK: - Factory

    @MainActor
    static func make(
        tasks: [TaskItem]? = nil,
        journalEntries: [JournalEntry]? = nil,
        moods: [DailyMood] = []
    ) -> ModelContainer {
        let previewTasks = tasks ?? SampleData.tasks
        let previewJournalEntries = journalEntries ?? SampleData.journalEntries

        do {
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: true
            )

            let container = try ModelContainer(
                for: TaskItem.self,
                DailyMood.self,
                JournalEntry.self,
                configurations: configuration
            )

            let context = container.mainContext

            previewTasks.forEach { task in
                context.insert(task)
            }

            previewJournalEntries.forEach { entry in
                context.insert(entry)
            }

            moods.forEach { mood in
                context.insert(mood)
            }

            if context.hasChanges {
                try context.save()
            }

            return container
        } catch {
            fatalError(
                "Failed to prepare preview container: \(error)"
            )
        }
    }
}
