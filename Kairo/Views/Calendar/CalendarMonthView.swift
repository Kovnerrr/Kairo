//
//  CalendarMonthView.swift
//  Kairo
//
//  Created by Andrii Kovner on 19.10.26.
//

import SwiftUI
import UIKit

struct CalendarMonthView: UIViewRepresentable {
    @Binding var selectedDate: Date
    
    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        
        calendarView.calendar = .current
        calendarView.locale = .current
        calendarView.timeZone = .current
        
        let selection = UICalendarSelectionSingleDate(delegate: context.coordinator)
        
        selection.selectedDate = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: selectedDate
        )
        
        calendarView.selectionBehavior = selection
        
        return calendarView
    }
    
    func updateUIView(_ uiView: UICalendarView, context: Context) {
        guard let selection = uiView.selectionBehavior as? UICalendarSelectionSingleDate else {
            return
        }
        
        let selectedComponents = Calendar.current.dateComponents(
            [.year, .month, .day],
            from: selectedDate
        )
        
        if selection.selectedDate != selectedComponents {
            selection.setSelected(selectedComponents, animated: false)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject, UICalendarSelectionSingleDateDelegate {
        var parent: CalendarMonthView
        
        init(parent: CalendarMonthView) {
            self.parent = parent
        }
        
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
    }
}

#Preview {
    @Previewable @State var selectedDate = Date.now
    
    CalendarMonthView(selectedDate: $selectedDate)
        .padding()
}
