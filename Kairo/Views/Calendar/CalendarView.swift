//
//  CalendarView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI

struct CalendarView: View {
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ContentUnavailableView(
                    "Calendar",
                    systemImage: "calendar",
                    description: Text("Your daily activity will appear here.")
                )
            }
            .navigationTitle("Calendar")
        }
    }
}

#Preview {
    CalendarView()
}
