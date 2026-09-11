//
//  KairoApp.swift
//  Kairo
//
//  Created by Andrii Kovner on 06.06.26.
//

import SwiftUI
import SwiftData

@main
struct KairoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .font(AppTheme.Typography.body)
                .tint(AppTheme.accent)
        }
        // The model container makes SwiftData models available
        // throughout the app`s SwiftUI hierarchy.
        .modelContainer(for: [TaskItem.self, DailyMood.self])
    }
}
