//
//  TodayView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    // MARK: - Data
    
    @Query private var tasks: [TaskItem]
    
    // MARK: - Computed Properties
    
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
                            
                            HStack(spacing: 12) {
                                Image(systemName: "face.smiling")
                                    .font(.title2)
                                    .foregroundStyle(AppTheme.accent)
                                    .accessibilityHidden(true)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("How are you feeling today?")
                                        .font(AppTheme.Typography.cardTitle)
                                        .foregroundStyle(.primary)
                                    
                                    Text("Mood tracking is coming soon")
                                        .font(AppTheme.Typography.secondary)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .padding()
                            .background(AppTheme.surface)
                            .clipShape(
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                            )
                            .overlay {
                                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                                    .stroke(AppTheme.border, lineWidth: 1)
                            }
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
        }
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewContainer.container)
}
