//
//  TaskFilterSheetView.swift
//  Kairo
//
//  Created by Andrii Kovner on 30.07.26.
//

import SwiftUI

struct TaskFilterSheetView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Dependencies
    
    @Bindable var viewModel: TaskListViewModel
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                filterSection
                
                if viewModel.selectedFilter == .priority {
                    prioritySection
                }
                
                sortSection
                resetSection
            }
            .navigationTitle("Filter & Sort")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var filterSection: some View {
        Section("Filter") {
            Picker(
                "Task filter",
                selection: $viewModel.selectedFilter
            ) {
                ForEach(TaskFilter.allCases) { filter in
                    Text(filter.title)
                        .tag(filter)
                }
            }
            .pickerStyle(.inline)
            // Keeps the label available to VoiceOver while hiding it visually.
            .labelsHidden()
        }
    }
    
    private var prioritySection: some View {
        Section("Priority") {
            Picker(
                "Task priority",
                selection: $viewModel.selectedPriority
            ) {
                ForEach(TaskPriority.allCases) { priority in
                    Text(priority.title)
                        .tag(priority)
                }
            }
            .pickerStyle(.inline)
            // Keeps the label available to VoiceOver while hiding it visually.
            .labelsHidden()
        }
    }
    
    private var sortSection: some View {
        Section("Sort") {
            Picker(
                "Task sorting",
                selection: $viewModel.selectedSortOption
            ) {
                ForEach(TaskSortOption.allCases) { sortOption in
                    Text(sortOption.title)
                        .tag(sortOption)
                }
            }
            .pickerStyle(.inline)
            // Keeps the label available to VoiceOver while hiding it visually.
            .labelsHidden()
        }
    }
    
    private var resetSection: some View {
        Section {
            Button("Reset Filters") {
                viewModel.resetControls()
            }
            .accessibilityHint(
                "Restores the default filter and sorting without clearing search."
            )
        }
    }
}

#Preview {
    TaskFilterSheetView(viewModel: TaskListViewModel())
}
