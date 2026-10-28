//
//  CalendarMonthView.swift
//  Kairo
//
//  Created by Andrii Kovner on 19.10.26.
//

import SwiftUI
import UIKit

struct CalendarMonthView: UIViewRepresentable {
    
    // MARK: - Properties
    
    @Binding var selectedDate: Date
    @Binding var displayedMonth: Date
    let taskDayStatuses: [DateComponents: Bool]
    
    // MARK: - UIViewRepresentable
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.timeZone = .current
        calendarView.delegate = context.coordinator
        
        calendarView.setVisibleDateComponents(
            Calendar.current.dateComponents(
                [.year, .month],
                from: displayedMonth
            ),
            animated: false
        )
        
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        
        selection.selectedDate = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: selectedDate
        )
        
        calendarView.selectionBehavior = selection
        
        context.coordinator.previousTaskDayStatuses = taskDayStatuses
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self
        
        // Reload decorations only for days whose task status changed.

        let oldStatuses = context.coordinator.previousTaskDayStatuses

        if oldStatuses != taskDayStatuses {

            // Include removed days to clear their old decorations.
            
            let changedDays = Set(oldStatuses.keys)
                .union(taskDayStatuses.keys)
                .filter { day in
                    oldStatuses[day] != taskDayStatuses[day]
                }

            context.coordinator.previousTaskDayStatuses = taskDayStatuses

            if !changedDays.isEmpty {
                uiView.reloadDecorations(
                    forDateComponents: Array(changedDays),
                    animated: false
                )
            }
        }

        let calendar = uiView.calendar

        if let visibleDate = calendar.date(
            from: uiView.visibleDateComponents
        ),
           !calendar.isDate(
               visibleDate,
               equalTo: displayedMonth,
               toGranularity: .month
           ) {
            let targetMonth = calendar.dateComponents(
                [.year, .month],
                from: displayedMonth
            )
            
            uiView.setVisibleDateComponents(
                targetMonth,
                animated: false
            )
        }

        guard let selection = uiView.selectionBehavior
            as? UICalendarSelectionSingleDate else {
            return
        }

        let selectedComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: selectedDate
        )

        if let uiSelectedComponents = selection.selectedDate,
           let uiSelectedDate = calendar.date(from: uiSelectedComponents),
           calendar.isDate(uiSelectedDate, inSameDayAs: selectedDate) {
            return
        }

        selection.setSelected(
            selectedComponents,
            animated: false
        )
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // MARK: - Coordinator
    
    final class Coordinator: NSObject,
                             UICalendarSelectionSingleDateDelegate,
                             UICalendarViewDelegate {
        
        // MARK: - Properties
        
        var parent: CalendarMonthView
        var previousTaskDayStatuses: [DateComponents: Bool] = [:]
        
        // MARK: - Initialization
        
        init(parent: CalendarMonthView) {
            self.parent = parent
        }

        // MARK: - Selection
        
        func dateSelection(
            _ selection: UICalendarSelectionSingleDate,
            didSelectDate dateComponents: DateComponents?
        ) {
            guard let dateComponents,
                  let date = Calendar.current.date(from: dateComponents) else {
                return
            }

            parent.selectedDate = date
        }

        // MARK: - Visible Month
        
        func calendarView(
            _ calendarView: UICalendarView,
            didChangeVisibleDateComponentsFrom previousDateComponents: DateComponents
        ) {
            let calendar = calendarView.calendar

            guard let visibleDate = calendar.date(
                from: calendarView.visibleDateComponents
            ) else {
                return
            }

            guard !calendar.isDate(
                visibleDate,
                equalTo: parent.displayedMonth,
                toGranularity: .month
            ) else {
                return
            }

            parent.displayedMonth = visibleDate
        }
        
        // MARK: - Calendar Decorations
        
        func calendarView(
            _ calendarView: UICalendarView,
            decorationFor dateComponents: DateComponents
        ) -> UICalendarView.Decoration? {
            let calendar = calendarView.calendar

            guard let date = calendar.date(from: dateComponents) else {
                return nil
            }

            let day = calendar.dateComponents(
                [.year, .month, .day],
                from: date
            )

            guard let allCompleted = parent.taskDayStatuses[day] else {
                return nil
            }

            return .default(
                color: allCompleted ? .systemGreen : .systemBlue,
                size: .small
            )
        }
    }
}

// MARK: - Previews

#Preview("Task Indicators") {
    @Previewable @State var selectedDate = Date.now
    @Previewable @State var displayedMonth = Date.now

    let calendar = Calendar.current

    let today = calendar.dateComponents(
        [.year, .month, .day],
        from: .now
    )

    let tomorrowDate = calendar.date(
        byAdding: .day,
        value: 1,
        to: .now
    ) ?? .now

    let tomorrow = calendar.dateComponents(
        [.year, .month, .day],
        from: tomorrowDate
    )

    CalendarMonthView(
        selectedDate: $selectedDate,
        displayedMonth: $displayedMonth,
        taskDayStatuses: [
            today: false,
            tomorrow: true
        ]
    )
    .padding()
    .tint(AppTheme.accent)
}
