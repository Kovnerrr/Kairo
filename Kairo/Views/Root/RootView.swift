//
//  RootView.swift
//  Kairo
//
//  Created by Andrii Kovner on 13.06.26.
//

import SwiftUI
import SwiftData

/// Hosts the main tabs of the app.
struct RootView: View {
    // MARK: - Types
    private enum AppTab: Hashable {
        case today
        case tasks
        case journal
        case calendar
    }
    
    // MARK: - State
    @State private var selectedTab: AppTab = .tasks
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(
                "Today",
                systemImage: "sun.max",
                value: .today
            ) {
                TodayView()
            }
            
            Tab(
                "Tasks",
                systemImage: "checklist",
                value: .tasks
            ) {
                TasksView()
            }
            
            Tab(
                "Journal",
                systemImage: "book.closed",
                value: .journal
            ) {
                JournalView()
            }
            
            Tab(
                "Calendar",
                systemImage: "calendar",
                value: .calendar
            ) {
                CalendarView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Main Tabs") {
    RootView()
        .modelContainer(PreviewContainer.container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}
