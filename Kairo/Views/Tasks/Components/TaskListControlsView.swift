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
            
            if viewModel.selectedFilter == .priority {
                Picker("Priority", selection: $viewModel.selectedPriority) {
                    ForEach(TaskPriority.allCases) { priority in
                        Text(priority.title)
                            .tag(priority)
                    }
                }
            }
            
            Picker("Sort", selection: $viewModel.selectedSortOption) {
                ForEach(TaskSortOption.allCases) { sortOption in
                    Text(sortOption.title)
                        .tag(sortOption)
                }
            }
        }
    }
}

#Preview {
    List {
        TaskListControlsView(viewModel: TaskListViewModel())
    }
}
