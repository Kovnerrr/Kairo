//
//  SampleData.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import Foundation

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
