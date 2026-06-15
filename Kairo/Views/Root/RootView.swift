//
//  RootView.swift
//  Kairo
//
//  Created by Andrii Kovner on 13.06.26.
//

import SwiftUI

/// The first view of the app.
/// Later, this view will decide whether to show onboarding or the main home screen.
struct RootView: View {
    // MARK: - Body
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.blue)
            
            Text("Kairo")
                .font(.largeTitle.bold())
            
            Text("Your tasks, organized with flow")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

#Preview {
    RootView()
}
