//
//  SampleData.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import Foundation

///Provides sample tasks for previews and development.
enum SampleData {
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
                taskDescription: "Thinking about future German Course, and buy everything what i need",
                dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now,
                priority: .medium,
                category: .study,
                isCompleted: true,
                completedAt: .now
            )
        ]
    }
}
