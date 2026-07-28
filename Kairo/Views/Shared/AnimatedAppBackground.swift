//
//  AnimatedAppBackground.swift
//  Kairo
//
//  Created by Andrii Kovner on 14.07.26.
//

import SwiftUI

struct AnimatedAppBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: reduceMotion
            )
        ) { context in
            gradient(
                at: reduceMotion
                    ? 0
                    : context.date.timeIntervalSinceReferenceDate
            )
        }
    }
    
    // MARK: - Gradient
    
    private var colors: [Color] {
        [
            AppTheme.gradientTop, AppTheme.gradientTop, AppTheme.gradientMiddle,
            AppTheme.gradientGreen, AppTheme.gradientMiddle, AppTheme.gradientMiddle,
            AppTheme.gradientGreen, AppTheme.gradientGreen, AppTheme.gradientBottom
        ]
    }
    
    private func gradient(at time: TimeInterval) -> some View {
        let horizontalWave = Float(sin(time * 0.90))
        let verticalWave = Float(cos(time * 0.70))

        return MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0],
                [0.5, 0],
                [1, 0],

                [0, 0.26 + 0.10 * verticalWave],
                [
                    0.50 + 0.22 * horizontalWave,
                    0.50 + 0.16 * verticalWave
                ],
                [1, 0.50 - 0.10 * verticalWave],

                [0, 1],
                [0.52 - 0.12 * horizontalWave, 1],
                [1, 1]
            ],
            colors: colors,
            background: AppTheme.background,
            smoothsColors: true,
            colorSpace: .perceptual
        )
    }
}

#Preview {
    AnimatedAppBackground()
        .ignoresSafeArea()
}
