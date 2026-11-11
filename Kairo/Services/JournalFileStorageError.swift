//
//  JournalFileStorageError.swift
//  Kairo
//
//  Created by Andrii Kovner on 05.11.26.
//

import Foundation

enum JournalFileStorageError: LocalizedError {
    case unsupportedType
    case fileTooLarge
    case emptyFile
    case invalidPDF
    case invalidTextEncoding
    case accessDenied
    case fileUnavailable
    case sessionUnavailable
    case invalidStoredFileName
    
    var errorDescription: String? {
        switch self {
        case .unsupportedType:
            "Only PDF and TXT files are supported."
            
        case .fileTooLarge:
            "The file must be 10 MB or smaller."
            
        case .emptyFile:
            "The selected file is empty."
            
        case .invalidPDF:
            "The PDF file could not be opened."
            
        case .invalidTextEncoding:
            "Only UTF-8 text files are supported."
            
        case .accessDenied:
            "Kairo could not access the selected file."
            
        case .fileUnavailable:
            "The selected file is unavailable."
            
        case .sessionUnavailable:
            "The file import session is no longer available."
            
        case .invalidStoredFileName:
            "The stored document filename is invalid."
        }
    }
}
