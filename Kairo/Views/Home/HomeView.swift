//
//  HomeView.swift
//  Kairo
//
//  Created by Andrii Kovner on 22.06.26.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Data
    @Query private var tasks: [TaskItem]
    
    // MARK: - State
    @State private var viewModel = TaskListViewModel()
    
    // MARK: - Body
    var body: some View {
        let statistics = viewModel.statistics(from: tasks)
        let visibleTasks = viewModel.filteredAndSortedTasks(from: tasks)
        
        NavigationStack {
            List {
                Section {
                    StatisticsHeaderView(statistics: statistics)
                }
                
                Section("Tasks") {
                    if visibleTasks.isEmpty {
                        EmptyStateView(
                            systemImageName: "tray",
                            title: "No tasks yet",
                            message: "Tap the plus button to create your first task"
                        )
                    } else {
                        ForEach(visibleTasks, id: \.id) { task in
                            TaskCardView(task: task)
                        }
                    }
                }
            }
            .navigationTitle("Kairo")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.openCreateForm()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Task")
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewContainer.container)
}
