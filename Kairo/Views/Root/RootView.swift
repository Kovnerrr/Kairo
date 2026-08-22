//
//  RootView.swift
//  Kairo
//
//  Created by Andrii Kovner on 13.06.26.
//

import SwiftUI
import SwiftData

/// The first view of the app.
/// Later, this view will decide whether to show onboarding or the main home screen.
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

#Preview {
    RootView()
        .modelContainer(PreviewContainer.container)
}
