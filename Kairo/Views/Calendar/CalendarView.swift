//
//  CalendarView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    // MARK: - State
    
    @State private var selectedDate = Date.now
    @State private var displayedMonth = Date.now
    @State private var taskToOpenID: UUID?
    @State private var journalEntryToOpenID: UUID?
    
    // MARK: - Data
    
    @Query private var tasks: [TaskItem]
    @Query private var moods: [DailyMood]
    @Query private var journalEntries: [JournalEntry]
    
    // MARK: - Computed Properties
    
    private var selectedDayMood: DailyMood? {
        let dayKey = MoodDayKey.make(for: selectedDate)

        return moods.first { mood in
            mood.dayKey == dayKey
        }
    }
    
    private var selectedDayJournalEntries: [JournalEntry] {
        guard let dayInterval = Calendar.current.dateInterval(
            of: .day,
            for: selectedDate
        ) else {
            return []
        }

        return journalEntries
            .filter { entry in
                entry.entryDate >= dayInterval.start &&
                entry.entryDate < dayInterval.end
            }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt > rhs.createdAt
                }

                return lhs.id.uuidString < rhs.id.uuidString
            }
    }
    
    private var selectedDayTasks: [TaskItem] {
        guard let dayInterval = Calendar.current.dateInterval(
            of: .day,
            for: selectedDate
        ) else {
            return []
        }
        
        return tasks
            .filter { task in
                task.dueDate >= dayInterval.start &&
                task.dueDate < dayInterval.end
            }
            .sorted { lhs, rhs in
                
                // Show active tasks before completed tasks.
                
                if lhs.isCompleted != rhs.isCompleted {
                    return !lhs.isCompleted
                }
                
                // Sort by due date within each completion group.
                
                if lhs.dueDate != rhs.dueDate {
                    return lhs.dueDate < rhs.dueDate
                }
                
                // Use creation time when due dates match.
                
                if lhs.createdAt != rhs.createdAt {
                    return lhs.createdAt < rhs.createdAt
                }
                
                // Use a stable tie-breaker when both dates match.
                
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }
    
    private var taskDayStatuses: [DateComponents: Bool] {
        let calendar = Calendar.current
        let groupedTasks = Dictionary(grouping: tasks) { task in
            calendar.dateComponents(
                [.year, .month, .day],
                from: task.dueDate
            )
        }
        return groupedTasks.mapValues { tasksForDay in
            tasksForDay.allSatisfy(\.isCompleted)
        }
    }
    
    // MARK: - Actions
    
    private func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                AnimatedAppBackground()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                
                ScrollView {
                    VStack(spacing: 16) {
                        CalendarMonthView(
                            selectedDate: $selectedDate,
                            displayedMonth: $displayedMonth,
                            taskDayStatuses: taskDayStatuses
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tasks (\(selectedDayTasks.count))")
                                .font(AppTheme.Typography.sectionTitle)
                            
                            if selectedDayTasks.isEmpty {
                                Text("No tasks scheduled for this day.")
                                    .font(AppTheme.Typography.secondary)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(selectedDayTasks) { task in
                                    CalendarTaskRow(
                                        task: task,
                                        onToggleCompleted: {
                                            toggleTaskCompletion(task)
                                        },
                                        onOpenDetails: {
                                            taskToOpenID = task.id
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Mood

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood")
                                .font(AppTheme.Typography.sectionTitle)

                            if let dailyMood = selectedDayMood {
                                Label(
                                    dailyMood.mood.title,
                                    systemImage: dailyMood.mood.symbolName
                                )
                                .font(AppTheme.Typography.secondary)
                            } else {
                                Text("No mood recorded for this day.")
                                    .font(AppTheme.Typography.secondary)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Journal

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Journal")
                                .font(AppTheme.Typography.sectionTitle)

                            if selectedDayJournalEntries.isEmpty {
                                Text("No journal entries for this day.")
                                    .font(AppTheme.Typography.secondary)
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(selectedDayJournalEntries) { entry in
                                    Button {
                                        journalEntryToOpenID = entry.id
                                    } label: {
                                        JournalEntryCardView(entry: entry)
                                            .frame(
                                                maxWidth: .infinity,
                                                alignment: .leading
                                            )
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint("Opens journal entry")
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
            .navigationDestination(item: $taskToOpenID) { taskID in
                if let task = tasks.first(where: { $0.id == taskID }) {
                    TaskDetailView(task: task)
                } else {
                    ContentUnavailableView(
                        "Task Unavailable",
                        systemImage: "checklist",
                        description: Text("This task is no longer available.")
                    )
                }
            }
            .onChange(of: tasks.map(\.id)) { _, existingTaskIDs in
                guard let openedTaskID = taskToOpenID else {
                    return
                }

                if !existingTaskIDs.contains(openedTaskID) {
                    taskToOpenID = nil
                }
            }
            
            .navigationDestination(item: $journalEntryToOpenID) { entryID in
                if let entry = journalEntries.first(where: { $0.id == entryID }) {
                    JournalEntryDetailView(entry: entry)
                } else {
                    ContentUnavailableView(
                        "Journal Entry Unavailable",
                        systemImage: "book.closed",
                        description: Text("This journal entry is no longer available.")
                    )
                }
            }
            .onChange(of: journalEntries.map(\.id)) { _, existingEntryIDs in
                guard let openedEntryID = journalEntryToOpenID else {
                    return
                }

                if !existingEntryIDs.contains(openedEntryID) {
                    journalEntryToOpenID = nil
                }
            }
            
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Today") {
                        let today = Date.now
                        selectedDate = today
                        displayedMonth = today
                    }
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Calendar - Sample Data") {
    CalendarView()
        .modelContainer(PreviewContainer.container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Calendar - Empty") {
    CalendarView()
        .modelContainer(
            PreviewContainer.make(
                tasks: [],
                journalEntries: [],
                moods: []
            )
        )
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Calendar - Dark Mode") {
    CalendarView()
        .modelContainer(PreviewContainer.container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
}

#Preview("Calendar - Mood Only") {
    let mood = DailyMood(
        dayKey: MoodDayKey.make(for: .now),
        mood: .good
    )

    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: [],
        moods: [mood]
    )

    return CalendarView()
        .modelContainer(container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Calendar - Journal Only") {
    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: SampleData.journalEntries,
        moods: []
    )

    return CalendarView()
        .modelContainer(container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
}

#Preview("Calendar - Mixed Day / Large Type") {
    let now = Date.now

    let task = TaskItem(
        title: "Prepare the Calendar review and write down the next learning steps",
        dueDate: now,
        priority: .high,
        category: .study
    )

    let mood = DailyMood(
        dayKey: MoodDayKey.make(for: now),
        mood: .good
    )

    let container = PreviewContainer.make(
        tasks: [task],
        journalEntries: SampleData.journalEntries,
        moods: [mood]
    )

    return CalendarView()
        .modelContainer(container)
        .font(AppTheme.Typography.body)
        .tint(AppTheme.accent)
        .dynamicTypeSize(.accessibility3)
}
