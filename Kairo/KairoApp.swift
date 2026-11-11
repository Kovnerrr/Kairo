//
//  KairoApp.swift
//  Kairo
//
//  Created by Andrii Kovner on 06.06.26.
//

import SwiftUI
import SwiftData

@main
struct KairoApp: App {
    
    // MARK: - State
    
    @State private var startupPhase: JournalStartupPhase = .idle
    @State private var recoveryStorage = JournalFileStorage()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            JournalStartupView(
                phase: $startupPhase,
                fileStorage: recoveryStorage
            )
            .font(AppTheme.Typography.body)
            .tint(AppTheme.accent)
        }
        
        // The model container makes SwiftData models available
        // throughout the app's SwiftUI hierarchy.
        
        .modelContainer(for: [
            TaskItem.self,
            DailyMood.self,
            JournalEntry.self,
            JournalPhoto.self,
            JournalFile.self
        ])
    }
}

// MARK: - Startup State

private enum JournalStartupPhase {
    case idle
    case running
    case ready
    case failed(String)
}

// MARK: - Startup View

private struct JournalStartupView: View {
    @Environment(\.modelContext) private var modelContext

    @Binding var phase: JournalStartupPhase

    let fileStorage: JournalFileStorage

    var body: some View {
        ZStack {
            switch phase {
            case .idle, .running:
                ProgressView("Preparing Kairo…")

            case .ready:
                RootView()

            case .failed(let message):
                VStack(spacing: 16) {
                    Text("Document cleanup couldn't finish")
                        .font(.headline)

                    Text(message)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Try Again") {
                        Task {
                            await runRecovery()
                        }
                    }

                    Button("Continue Without Cleanup") {
                        phase = .ready
                    }
                }
                .padding()
            }
        }
        .task {
            guard case .idle = phase else {
                return
            }

            await runRecovery()
        }
    }

    @MainActor
    private func runRecovery() async {
        switch phase {
        case .running, .ready:
            return

        case .idle, .failed:
            break
        }

        phase = .running

        do {
            let files = try modelContext.fetch(
                FetchDescriptor<JournalFile>()
            )

            let referencedFileNames = Set(
                files.map(\.storedFileName)
            )

            try await fileStorage.recoverAtLaunch(
                referencedFileNames: referencedFileNames
            )

            phase = .ready

        } catch {
            phase = .failed(error.localizedDescription)
        }
    }
}
