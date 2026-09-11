//
//  TodayView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI
import SwiftData
import Foundation

struct TodayView: View {
    // MARK: - Data
    
    @Query private var tasks: [TaskItem]
    @Query private var moods: [DailyMood]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var moodSaveErrorMessage: String?
    @State private var currentDate = Date.now
    
    // MARK: - Computed Properties
    
    private var todayDayKey: String {
        dayKey(for: currentDate)
    }
    
    private func dayKey(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        
        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
    
    private var todayMood: DailyMood? {
        moods.first { mood in
            mood.dayKey == todayDayKey
        }
    }
    
    private var todayTasks: [TaskItem] {
        let calendar = Calendar.current
        
        return tasks
            .filter { task in
                calendar.isDateInToday(task.dueDate)
            }
            .sorted { firstTask, secondTask in
                if firstTask.isCompleted != secondTask.isCompleted {
                    return !firstTask.isCompleted
                }
                
                if firstTask.dueDate != secondTask.dueDate {
                    return firstTask.dueDate < secondTask.dueDate
                }
                
                if firstTask.createdAt != secondTask.createdAt {
                    return firstTask.createdAt < secondTask.createdAt
                }
                
                return firstTask.id.uuidString < secondTask.id.uuidString
            }
    }
    
    private var completedTodayTasks: [TaskItem] {
        todayTasks.filter(\.isCompleted)
    }
    
    private var todayCompletionRate: Double {
        guard !todayTasks.isEmpty else {
            return 0
        }
        
        return Double(completedTodayTasks.count) / Double(todayTasks.count)
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<18:
            return "Good afternoon"
        case 18..<22:
            return "Good evening"
        default:
            return "Good night"
        }
    }
    
    // MARK: - Actions
    
    private func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        task.completedAt = task.isCompleted ? .now : nil
    }
    
    private func selectMood(_ mood: MoodType) {
        let now = Date.now
        currentDate = now

        let currentDayKey = dayKey(for: now)

        if let existingMood = moods.first(where: {
            $0.dayKey == currentDayKey
        }) {
            guard existingMood.mood != mood else {
                return
            }

            let previousRawValue = existingMood.moodRawValue
            let previousUpdatedAt = existingMood.updatedAt

            existingMood.mood = mood
            existingMood.updatedAt = now

            do {
                try modelContext.save()
            } catch {
                existingMood.moodRawValue = previousRawValue
                existingMood.updatedAt = previousUpdatedAt
                moodSaveErrorMessage = error.localizedDescription
            }
        } else {
            let newMood = DailyMood(
                dayKey: currentDayKey,
                mood: mood,
                createdAt: now,
                updatedAt: now
            )

            modelContext.insert(newMood)

            do {
                try modelContext.save()
            } catch {
                modelContext.delete(newMood)
                moodSaveErrorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greeting)
                                .font(AppTheme.Typography.sectionTitle)
                                .foregroundStyle(.primary)
                            
                            Text(
                                Date.now,
                                format: .dateTime
                                    .weekday(.wide)
                                    .month(.wide)
                                    .day()
                            )
                            .font(AppTheme.Typography.secondary)
                            .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Today's Progress")
                                    .font(AppTheme.Typography.sectionTitle)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("\(completedTodayTasks.count)/\(todayTasks.count)")
                                    .font(AppTheme.Typography.secondary)
                                    .foregroundStyle(.secondary)
                            }
                            
                            ProgressView(value: todayCompletionRate)
                                .tint(AppTheme.accent)
                                .accessibilityLabel("Today's completion progress")
                                .accessibilityValue(
                                    "\(completedTodayTasks.count) of \(todayTasks.count) tasks completed"
                                )
                        }
                        .padding()
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                .stroke(AppTheme.border, lineWidth: 1)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Today's Tasks")
                                .font(AppTheme.Typography.sectionTitle)
                                .foregroundStyle(.primary)
                            
                            if todayTasks.isEmpty {
                                VStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.accent)
                                        .accessibilityHidden(true)
                                    
                                    Text("You're clear for today.")
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundStyle(.primary)
                                    
                                    Text("No tasks are due today.")
                                        .font(AppTheme.Typography.secondary)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.surface)
                                .clipShape(
                                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                        .stroke(AppTheme.border, lineWidth: 1)
                                }
                            } else {
                                ForEach(todayTasks) { task in
                                    TodayTaskRow(
                                        task: task,
                                        onToggleCompleted: {
                                            toggleTaskCompletion(task)
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Mood
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mood")
                                .font(AppTheme.Typography.sectionTitle)
                                .foregroundStyle(.primary)
                            
                            Text("How are you feeling today?")
                                .font(AppTheme.Typography.secondary)
                                .foregroundStyle(.secondary)
                            
                            MoodPickerView(
                                selectedMood: todayMood?.mood, onSelectMood: { mood in
                                    selectMood(mood)
                                }
                            )
                        }
                        
                        // Journal
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Journal")
                                .font(AppTheme.Typography.sectionTitle)
                                .foregroundStyle(.primary)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "book.closed")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.accent)
                                    .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Capture your day")
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Journal entries are coming soon")
                                        .font(AppTheme.Typography.secondary)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                currentDate = .now
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    currentDate = .now
                }
            }
            .task {
                for await _ in NotificationCenter.default.messages(
                    of: Calendar.self,
                    for: .calendarDayChanged
                ) {
                    currentDate = .now
                }
            }
            .alert(
                "Couldn't Save Mood",
                isPresented: Binding(
                    get: {
                        moodSaveErrorMessage != nil
                    },
                    set: { isPresented in
                        if !isPresented {
                            moodSaveErrorMessage = nil
                        }
                    }
                )
            ) {
                Button("OK", role: .cancel) {
                    moodSaveErrorMessage = nil
                }
            } message: {
                Text(
                    moodSaveErrorMessage ?? "An unknown error occurred."
                )
            }
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewContainer.container)
}
