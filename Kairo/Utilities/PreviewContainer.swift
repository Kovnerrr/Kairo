//
//  PreviewContainer.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import SwiftData

/// Creates an in-memory SwiftData container for previews.
enum PreviewContainer {
    @MainActor
    static var container: ModelContainer {
        do {
            let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
            
            let container = try ModelContainer(for: TaskItem.self, configurations: configuration)
            
            SampleData.tasks.forEach { task in container.mainContext.insert(task) }
            
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
