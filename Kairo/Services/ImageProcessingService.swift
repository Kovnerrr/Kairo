//
//  ImageProcessingService.swift
//  Kairo
//
//  Created by Andrii Kovner on 30.10.26.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

nonisolated enum ImageProcessingService {
    
    // MARK: - Configuration
    
    private static let fullImageMaxPixelSize = 2048
    private static let thumbnailMaxPixelSize = 400
    private static let jpegCompressionQuality: CGFloat = 0.8
    
    // MARK: - Result
    
    struct ProcessedImage: Sendable {
        let imageData: Data
        let thumbnailData: Data
    }
    
    // MARK: - Processing
    
    @concurrent
    static func process(_ data: Data) async throws -> ProcessedImage {
        try Task.checkCancellation()
        
        let fullImage = try makeJPEG(
            from: data,
            maxPixelSize: fullImageMaxPixelSize
        )
        
        try Task.checkCancellation()
        
        let thumbnail = try makeJPEG(
            from: data,
            maxPixelSize: thumbnailMaxPixelSize
        )
        
        try Task.checkCancellation()
        
        return ProcessedImage(
            imageData: fullImage, thumbnailData: thumbnail
        )
    }
    
    // MARK: - Private Methods
    
    private static func makeJPEG(
        from data: Data,
        maxPixelSize: Int
    ) throws -> Data {
        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            nil
        ) else {
            throw ProcessingError.invalidImage
        }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        
        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options as CFDictionary
        ) else {
            throw ProcessingError.invalidImage
        }
        
        let output = NSMutableData()
        
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            throw ProcessingError.encodingFailed
        }
        
        let destinationOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: jpegCompressionQuality
        ]
        
        CGImageDestinationAddImage(
            destination,
            image,
            destinationOptions as CFDictionary
        )
        
        guard CGImageDestinationFinalize(destination) else {
            throw ProcessingError.encodingFailed
        }
         
        return output as Data
    }
    
    // MARK: - Errors
    
    enum ProcessingError: LocalizedError {
        case invalidImage
        case encodingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidImage:
                "The selected image could not be opened."
            case .encodingFailed:
                "The selected image could not be processed."
            }
        }
    }
}
