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
        }
        // The model container makes TaskItem available to SwiftData
        // throughout the app`s SwiftUI hierarchy.
        .modelContainer(for: TaskItem.self)
    }
}
