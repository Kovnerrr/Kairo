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
        if reduceMotion {
            gradient
                .scaleEffect(1.60)
        } else {
            gradient
                .phaseAnimator([false, true]) { content, phase in
                    content
                        .scaleEffect(phase ? 1.65 : 1.55)
                        .offset(
                            x: phase ? 90 : -90,
                            y: phase ? -65 : 65
                        )
                        .rotationEffect(
                            .degrees(phase ? 4 : -4)
                        )
                } animation: { _ in
                    .easeInOut(duration: 5)
                }
        }
    }
    
    // MARK: - Gradient
    
    private var colors: [Color] {
        [
            AppTheme.gradientTop, AppTheme.gradientTop, AppTheme.gradientMiddle,
            AppTheme.gradientGreen, AppTheme.surface, AppTheme.gradientMiddle,
            AppTheme.gradientGreen, AppTheme.gradientGreen, AppTheme.gradientBottom
        ]
    }
    
    private var gradient: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0],
                [0.5, 0],
                [1, 0],

                [0, 0.40],
                [0.5, 0.55],
                [1, 0.50],

                [0, 1],
                [0.52, 1],
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
