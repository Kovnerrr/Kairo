//
//  AppTheme.swift
//  Kairo
//
//  Created by Andrii Kovner on 09.07.26.
//

import SwiftUI
// MARK: - Colors

enum AppTheme {
    static let background = Color("KairoBackground")
    static let surface = Color("KairoSurface")
    static let accent = Color("KairoAccent")
    static let accentSoft = Color("KairoAccentSoft")
    static let border = Color("KairoBorder")
    static let gradientTop = Color("KairoGradientTop")
    static let gradientMiddle = Color("KairoGradientMiddle")
    static let gradientBottom = Color("KairoGradientBottom")
    static let gradientGreen = Color("KairoGradientGreen")
    
    
    // MARK: - Layout
    
    static let cardCornerRadius: CGFloat = 8
    
    // MARK: - Typography
    
    enum Typography {
        private static let regularFontName = "Comfortaa-Regular"
        private static let mediumFontName = "Comfortaa-Medium"
        private static let semiboldFontName = "Comfortaa-SemiBold"
        private static let boldFontName = "Comfortaa-Bold"
        
        static let sectionTitle = Font.custom(semiboldFontName, size: 18, relativeTo: .headline)
        static let cardTitle = Font.custom(semiboldFontName, size: 16, relativeTo: .headline)
        static let body = Font.custom(regularFontName, size: 16, relativeTo: .body)
        static let secondary = Font.custom(regularFontName, size: 14, relativeTo: .subheadline)
        static let badge = Font.custom(mediumFontName, size: 11, relativeTo: .caption)
        static let statisticNumber = Font.custom(boldFontName, size: 23, relativeTo: .title2)
        static let button = Font.custom(semiboldFontName, size: 16, relativeTo: .body)
        static let textField = Font.custom(regularFontName, size: 16, relativeTo: .body)
        static let appName = Font.custom(
            "BadScript-Regular",
            size: 46,
            relativeTo: .largeTitle
        )
    }
}
