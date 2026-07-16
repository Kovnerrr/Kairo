//
//  TaskListControlsView.swift
//  Kairo
//
//  Created by Andrii Kovner on 04.07.26.
//

import SwiftUI

struct TaskListControlsView: View {
    @Bindable var viewModel: TaskListViewModel
    
    var body: some View {
        Section("Controls") {
            Picker("Filter", selection: $viewModel.selectedFilter) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.title)
                        .tag(filter)
                }
            }
            .listRowBackground(AppTheme.surface)
            
            if viewModel.selectedFilter == .priority {
                Picker("Priority", selection: $viewModel.selectedPriority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.title)
                            .tag(priority)
                    }
                }
                .listRowBackground(AppTheme.surface)
            }
            
            Picker("Sort", selection: $viewModel.selectedSortOption) {
                ForEach(TaskSortOption.allCases) { sortOption in
                    Text(sortOption.title)
                        .tag(sortOption)
                }
            }
            .listRowBackground(AppTheme.surface)
        }
    }
}

#Preview {
    List {
        TaskListControlsView(viewModel: TaskListViewModel())
    }
    .scrollContentBackground(.hidden)
    .background(AppTheme.background)
}
