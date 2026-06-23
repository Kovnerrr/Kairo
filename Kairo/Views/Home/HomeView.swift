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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total: \(statistics.total)")
                        Text("Completed: \(statistics.completed)")
                        Text("Pending: \(statistics.pending)")
                    }
                }
                
                Section("Tasks") {
                    ForEach(visibleTasks, id: \.id) { task in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.headline)
                            
                            Text(task.category.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(task.priority.title)
                                .font(.caption)
                                .foregroundStyle(.secondary)
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
