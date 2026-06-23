//
//  RootView.swift
//  Kairo
//
//  Created by Andrii Kovner on 13.06.26.
//

import SwiftUI
import SwiftData

/// The first view of the app.
/// Later, this view will decide whether to show onboarding or the main home screen.
struct RootView: View {
    // MARK: - Body
    var body: some View {
        HomeView()
    }
}

#Preview {
    RootView()
        .modelContainer(PreviewContainer.container)
}
