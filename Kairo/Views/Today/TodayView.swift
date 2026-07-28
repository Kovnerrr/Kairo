//
//  TodayView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI

struct TodayView: View {
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ContentUnavailableView(
                    "Today",
                    systemImage: "sun.max",
                    description: Text("Your daily overview will appear here.")
                )
            }
            .navigationTitle("Today")
        }
    }
}

#Preview {
    TodayView()
}
