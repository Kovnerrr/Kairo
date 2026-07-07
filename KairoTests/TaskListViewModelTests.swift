//
//  TaskListViewModelTests.swift
//  KairoTests
//
//  Created by Andrii Kovner on 06.06.26.
//

import Foundation
import Testing
@testable import Kairo

@MainActor
struct TaskListViewModelTests {
    private let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)
    
    private func date(daysFromReference days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: referenceDate) ?? referenceDate
    }
    
    private func makeTask(
        title: String,
        taskDescription: String? = nil,
        dueDate: Date? = nil,
        priority: TaskPriority = .medium,
        category: TaskCategory = .personal,
        isCompleted: Bool = false
    ) -> TaskItem {
        TaskItem(
            title: title,
            taskDescription: taskDescription,
            dueDate: dueDate ?? referenceDate,
            priority: priority,
            category: category,
            isCompleted: isCompleted,
            completedAt: isCompleted ? referenceDate : nil
        )
    }
    
    @Test
    func statisticsForEmptyList() {
        let viewModel = TaskListViewModel()
        
        let statistics = viewModel.statistics(from: [])
        
        #expect(statistics.total == 0)
        #expect(statistics.completed == 0)
        #expect(statistics.pending == 0)
        #expect(statistics.completionRate == 0)
    }
    
    @Test
    func statisticsCountsCompletedAndPendingTasks() {
        let viewModel = TaskListViewModel()
        
        let tasks = [
            makeTask(title: "One"),
            makeTask(title: "Two", isCompleted: true),
            makeTask(title: "Three")
        ]
        
        let statistics = viewModel.statistics(from: tasks)
        
        #expect(statistics.total == 3)
        #expect(statistics.completed == 1)
        #expect(statistics.pending == 2)
        #expect(abs(statistics.completionRate - (1.0 / 3.0)) < 0.0001)
    }
    
    @Test
    func allFilterReturnsAllTasks() {
        let viewModel = TaskListViewModel()
        viewModel.selectedFilter = .all
        
        let result = viewModel.filteredAndSortedTasks(from: [
            makeTask(
                title: "First",
                dueDate: date(daysFromReference: 0)
            ),
            makeTask(
                title: "Second",
                dueDate: date(daysFromReference: 1),
                isCompleted: true
            )
        ])
        
        #expect(result.map(\.title) == ["First", "Second"])
    }
    
    @Test
    func activeFilterReturnsOnlyActiveTasks() {
        let viewModel = TaskListViewModel()
        viewModel.selectedFilter = .active
        
        let activeTask = makeTask(title: "Active")
        let completeTask = makeTask(title: "Completed", isCompleted: true)
        
        let result = viewModel.filteredAndSortedTasks(from: [activeTask, completeTask])
        
        #expect(result.map(\.title) == ["Active"])
    }
    
    @Test
    func completedFilterReturnsOnlyCompletedTasks() {
        let viewModel = TaskListViewModel()
        viewModel.selectedFilter = .completed
        
        let activeTask = makeTask(title: "Active")
        let completedTask = makeTask(title: "Completed", isCompleted: true)
        
        let result = viewModel.filteredAndSortedTasks(from: [activeTask, completedTask])
        
        #expect(result.map(\.title) == ["Completed"])
    }
    
    @Test
    func priorityFilterReturnsOnlySelectedPriorityTasks() {
        let viewModel = TaskListViewModel()
        viewModel.selectedFilter = .priority
        viewModel.selectedPriority = .high
        
        let highTask = makeTask(title: "High", priority: .high)
        let lowTask = makeTask(title: "Low", priority: .low)
        
        let result = viewModel.filteredAndSortedTasks(from: [highTask, lowTask])
        
        #expect(result.map(\.title) == ["High"])
    }
    
    @Test
    func searchMatchesTaskTitle() {
        let viewModel = TaskListViewModel()
        viewModel.searchText = "milk"
        
        let matchingTask = makeTask(title: "Buy milk")
        let otherTask = makeTask(title: "Study German")
        
        let result = viewModel.filteredAndSortedTasks(from: [matchingTask, otherTask])
        
        #expect(result.map(\.title) == ["Buy milk"])
    }
    
    @Test
    func searchMatchesTaskDescription() {
        let viewModel = TaskListViewModel()
        viewModel.searchText = "portfolio"
        
        let matchingTask = makeTask(title: "Screenshots", taskDescription: "Prepare portfolio image")
        
        let otherTask = makeTask(title: "Buy water")
        
        let result = viewModel.filteredAndSortedTasks(from: [matchingTask, otherTask])
        
        #expect(result.map(\.title) == ["Screenshots"])
    }
    
    @Test
    func searchIsCaseInsensitive() {
        let viewModel = TaskListViewModel()
        viewModel.searchText = "SWIFT"
        
        let matchingTask = makeTask(title: "Study Swift")
        let otherTask = makeTask(title: "Buy milk")
        
        let result = viewModel.filteredAndSortedTasks(from: [matchingTask, otherTask])
        
        #expect(result.map(\.title) == ["Study Swift"])
    }
    
    @Test
    func searchTrimsWhitespace() {
        let viewModel = TaskListViewModel()
        viewModel.searchText = "    milk    "
        
        let matchingTask = makeTask(title: "Buy milk")
        let otherTask = makeTask(title: "Study Swift")
        
        let result = viewModel.filteredAndSortedTasks(from: [matchingTask, otherTask])
        
        #expect(result.map(\.title) == ["Buy milk"])
    }
    
    @Test
    func combinesActiveFilterAndSearch() {
        let viewModel = TaskListViewModel()
        viewModel.selectedFilter = .active
        viewModel.searchText = "deutsch"
        
        let activeMatchingTask = makeTask(title: "Study Deutsch")
        let completedMatchingTask = makeTask(title: "Read Deutsch book", isCompleted: true)
        let activeNonMatchingTask = makeTask(title: "Buy milk")
        
        let result = viewModel.filteredAndSortedTasks(from: [
            activeMatchingTask,
            completedMatchingTask,
            activeNonMatchingTask
        ])
        
        #expect(result.map(\.title) == ["Study Deutsch"])
    }
    
    @Test
    func sortByDueDateAscending() {
        let viewModel = TaskListViewModel()
        viewModel.selectedSortOption = .dueDateAscending
        
        let result = viewModel.filteredAndSortedTasks(from: [
            makeTask(title: "Tomorrow", dueDate: date(daysFromReference: 1)),
            makeTask(title: "Yesterday", dueDate: date(daysFromReference: -1)),
            makeTask(title: "Today", dueDate: date(daysFromReference: 0))
        ])
        
        #expect(result.map(\.title) == ["Yesterday", "Today", "Tomorrow"])
    }
    
    @Test
    func sortByDueDateDescending() {
        let viewModel = TaskListViewModel()
        viewModel.selectedSortOption = .dueDateDescending
        
        let result = viewModel.filteredAndSortedTasks(from: [
            makeTask(title: "Tomorrow", dueDate: date(daysFromReference: 1)),
            makeTask(title: "Today", dueDate: date(daysFromReference: 0)),
            makeTask(title: "Yesterday", dueDate: date(daysFromReference: -1))
        ])
        
        #expect(result.map(\.title) == ["Tomorrow", "Today", "Yesterday"])
    }
    
    @Test
    func sortByPriorityHighToLow() {
        let viewModel = TaskListViewModel()
        viewModel.selectedSortOption = .priorityHighToLow
        
        let result = viewModel.filteredAndSortedTasks(from: [
            makeTask(title: "Low", priority: .low),
            makeTask(title: "High", priority: .high),
            makeTask(title: "Medium", priority: .medium)
        ])
        
        #expect(result.map(\.title) == ["High", "Medium", "Low"])
    }
    
    @Test
    func sortByPriorityLowToHigh() {
        let viewModel = TaskListViewModel()
        viewModel.selectedSortOption = .priorityLowToHigh
        
        let result = viewModel.filteredAndSortedTasks(from: [
            makeTask(title: "High", priority: .high),
            makeTask(title: "Low", priority: .low),
            makeTask(title: "Medium", priority: .medium)
        ])
        
        #expect(result.map(\.title) == ["Low", "Medium", "High"])
    }
}
