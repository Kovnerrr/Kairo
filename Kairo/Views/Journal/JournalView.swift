//
//  JournalView.swift
//  Kairo
//
//  Created by Andrii Kovner on 28.07.26.
//

import SwiftUI

struct JournalView: View {
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()
                
                ContentUnavailableView(
                    "Journal",
                    systemImage: "book.closed",
                    description: Text("Your journal entries will appear here.")
                )
            }
            .navigationTitle("Journal")
        }
    }
}

#Preview {
    JournalView()
}
