//
//  TaskCategory.swift
//  Kairo
//
//  Created by Andrii Kovner on 15.06.26.
//

import Foundation

///Describe the life area a task belongs to.
enum TaskCategory: String, CaseIterable, Identifiable, Codable {
    case personal
    case work
    case study
    case health
    case other
    
    // MARK: - Identifiable
    var id: String { rawValue }
    
    // MARK: - Display
    var title: String {
        switch self {
        case .personal: "Personal"
        case .work: "Work"
        case .study: "Study"
        case .health: "Health"
        case .other: "Other"
        }
    }
    
    var systemImageName: String {
        switch self {
        case .personal: "person"
        case .work: "briefcase"
        case .study: "book"
        case .health: "heart"
        case .other: "tray"
        }
    }
}
