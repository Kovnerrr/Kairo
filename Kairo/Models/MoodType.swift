//
//  MoodType.swift
//  Kairo
//
//  Created by Andrii Kovner on 08.09.26.
//

import Foundation

enum MoodType: String, CaseIterable, Identifiable {
    case great
    case good
    case okay
    case low
    case bad
    
    var id: String {
        rawValue
    }
    
    var title: String {
        switch self {
        case .great:
            return "Great"
        case .good:
            return "Good"
        case .okay:
            return "Okay"
        case .low:
            return "Low"
        case .bad:
            return "Bad"
        }
    }
    
    var symbolName: String {
        switch self {
        case .great:
            return "face.smiling.inverse"
        case .good:
            return "face.smiling"
        case .okay:
            return "minus.circle"
        case .low:
            return "cloud"
        case .bad:
            return "cloud.rain"
        }
    }
}
