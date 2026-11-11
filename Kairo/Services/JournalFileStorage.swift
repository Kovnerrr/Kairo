//
//  JournalFileStorage.swift
//  Kairo
//
//  Created by Andrii Kovner on 04.11.26.
//

import Foundation
import CoreGraphics
import UniformTypeIdentifiers
import Dispatch
import OSLog

actor JournalFileStorage {
    
    // MARK: - Configuration
    
    private let maximumFileSize: Int64 = 10_000_000
    
    // MARK: - Properties
    
    private let fileManager: FileManager
    private let documentsDirectory: URL
    private let stagingDirectory: URL
    enum ImportSource: Sendable {
        case filesPicker(URL)
        case appOwned(URL)
    }

    private struct SessionState: Sendable {
        var activeImports = 0
        var isClosing = false
    }

    private var sessions: [UUID: SessionState] = [:]

    private let ioQueue = DispatchQueue(
        label: "Kairo.JournalFileStorage.import",
        qos: .utility
    )

    private let logger = Logger(
        subsystem: "Kairo",
        category: "JournalFileStorage"
    )
    
    // MARK: - Initialization
    
    init(
        fileManager: FileManager = .default,
        storageRoot: URL? = nil,
        temporaryRoot: URL? = nil
    ) {
        self.fileManager = fileManager
        let applicationSupport = storageRoot
        ?? fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ) [0]
        
        let temporaryDirectory = temporaryRoot
        ?? fileManager.temporaryDirectory
        
        self.documentsDirectory = applicationSupport
            .appending(
                path: "JournalFiles/Documents",
                directoryHint: .isDirectory
            )
        
        self.stagingDirectory = temporaryDirectory
            .appending(
                path: "KairoJournalFileStaging",
                directoryHint: .isDirectory
            )
    }
    
    // MARK: - Directory Management
    
    func prepareDirectories() throws {
        try fileManager.createDirectory(
            at: documentsDirectory,
            withIntermediateDirectories: true
        )
        
        try fileManager.createDirectory(
            at: stagingDirectory,
            withIntermediateDirectories: true
        )
    }
    
    // MARK: - Form Sessions

    func createSession() throws -> UUID {
        try prepareDirectories()

        let id = UUID()

        try fileManager.createDirectory(
            at: sessionDirectory(for: id),
            withIntermediateDirectories: false
        )

        sessions[id] = SessionState()
        return id
    }

    func removeSession(id: UUID) throws {
        guard sessions[id] != nil else {
            return
        }

        sessions[id]?.isClosing = true
        try removeClosedSessionIfIdle(id)
    }
    
    func closeSession(id: UUID) {
        do {
            try removeSession(id: id)
        } catch {
            logger.error(
                "Could not close a journal file session: \((error as NSError).code)"
            )
        }
    }

    private func sessionDirectory(for id: UUID) -> URL {
        stagingDirectory.appending(
            path: id.uuidString,
            directoryHint: .isDirectory
        )
    }

    // MARK: - Import Lifecycle

    private func beginImport(sessionID: UUID) throws {
        guard sessions[sessionID]?.isClosing == false else {
            throw JournalFileStorageError.sessionUnavailable
        }

        sessions[sessionID]?.activeImports += 1
    }

    private func finishImport(sessionID: UUID) {
        sessions[sessionID]?.activeImports -= 1

        do {
            try removeClosedSessionIfIdle(sessionID)
        } catch {
            logger.error(
                "Could not remove a closed import session: \((error as NSError).code)"
            )
        }
    }

    private func removeClosedSessionIfIdle(_ id: UUID) throws {
        guard let state = sessions[id],
              state.isClosing,
              state.activeImports == 0 else {
            return
        }

        try removeIfPresent(sessionDirectory(for: id), using: fileManager)
        sessions[id] = nil
    }

    // MARK: - File Cleanup

    private nonisolated func removeIfPresent(
        _ url: URL,
        using manager: FileManager
    ) throws {
        do {
            try manager.removeItem(at: url)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            return
        }
    }

    private nonisolated func discardCopy(
        at url: URL,
        using manager: FileManager
    ) {
        do {
            try removeIfPresent(url, using: manager)
        } catch {
            logger.error(
                "Could not discard a staged file: \((error as NSError).code)"
            )
        }
    }
    
    // MARK: - File Validation
    
    private nonisolated func validateFileSize(
        at url: URL
    ) throws -> Int64 {
        let values = try url.resourceValues(
            forKeys: [
                .isRegularFileKey,
                .isSymbolicLinkKey,
                .fileSizeKey
            ]
        )
        
        guard values.isRegularFile == true,
              values.isSymbolicLink != true else {
            throw JournalFileStorageError.fileUnavailable
        }
        
        guard let size = values.fileSize else {
            throw JournalFileStorageError.fileUnavailable
        }
        
        let fileSize = Int64(size)
        
        guard fileSize > 0 else {
            throw JournalFileStorageError.emptyFile
        }
        
        guard fileSize <= maximumFileSize else {
            throw JournalFileStorageError.fileTooLarge
        }
        
        return fileSize
    }
    
    private nonisolated func validateDocument(
        at url: URL,
        contentType: UTType
    ) throws {
        
        if contentType == .pdf {
            guard let document = CGPDFDocument(
                url as CFURL
            ),
                  document.isEncrypted == false,
                  document.numberOfPages > 0 else {
                throw JournalFileStorageError.invalidPDF
            }
            
        } else if contentType == .plainText {
            let data = try Data(contentsOf: url)
            
            guard String(
                data: data, encoding: .utf8
            ) != nil else {
                throw JournalFileStorageError.invalidTextEncoding
            }
            
        } else {
            throw JournalFileStorageError.unsupportedType
        }
    }
    
    // MARK: - File Import
    
    func importFile(
        from source: ImportSource,
        sessionID: UUID
    ) async throws -> ImportedJournalFile {
        try Task.checkCancellation()
        try beginImport(sessionID: sessionID)
        
        defer {
            finishImport(sessionID: sessionID)
        }
        
        let directory = sessionDirectory(for: sessionID)
        
        let file: ImportedJournalFile = try await withCheckedThrowingContinuation {
            continuation in
            ioQueue.async {
                continuation.resume(with: Result {
                    try self.copyToStaging(
                        from: source,
                        directory: directory,
                        sessionID: sessionID
                    )
                })
            }
        }
        
        do {
            try Task.checkCancellation()
            
            guard sessions[sessionID]?.isClosing == false else {
                throw JournalFileStorageError.sessionUnavailable
            }
            return file
        } catch {
            discardCopy(at: file.temporaryURL, using: fileManager)
            throw error
        }
    }
    
    // MARK: - Permanent File Storage
    
    func preparePermanentCopies(
        from drafts: [JournalFileDraft]
    ) async throws -> [PreparedJournalFile] {
        var preparedFiles: [PreparedJournalFile] = []

        do {
            for draft in drafts {
                guard case let .imported(importedFile) = draft else {
                    continue
                }

                try Task.checkCancellation()

                let prepared = try await preparePermanentCopy(
                    from: importedFile
                )

                preparedFiles.append(prepared)
            }

            try Task.checkCancellation()
            return preparedFiles

        } catch {
            removePermanentFiles(
                storedFileNames: preparedFiles.map(\.storedFileName)
            )

            throw error
        }
    }

    func preparePermanentCopy(
        from importedFile: ImportedJournalFile
    ) async throws -> PreparedJournalFile {

        // Check whether the task has been cancelled.
        try Task.checkCancellation()

        // Register an active operation for this session.
        try beginImport(sessionID: importedFile.formSessionID)

        // Always finish the operation when leaving this method.
        defer {
            finishImport(sessionID: importedFile.formSessionID)
        }

        // Verify that the file belongs to this session.
        let sessionURL = sessionDirectory(
            for: importedFile.formSessionID
        )

        let sourceURL = importedFile.temporaryURL.standardizedFileURL

        guard sourceURL.deletingLastPathComponent().standardizedFileURL
                == sessionURL.standardizedFileURL,
              sourceURL.deletingPathExtension().lastPathComponent
                == importedFile.id.uuidString,
              ["pdf", "txt"].contains(sourceURL.pathExtension.lowercased()) else {
            throw JournalFileStorageError.fileUnavailable
        }

        // Prepare the permanent storage directory.
        try prepareDirectories()

        let directory = documentsDirectory

        // Perform blocking file operations on a background queue.
        let prepared: PreparedJournalFile =
            try await withCheckedThrowingContinuation { continuation in

                ioQueue.async {
                    continuation.resume(
                        with: Result {
                            try self.copyToPermanentStorage(
                                importedFile: importedFile,
                                directory: directory
                            )
                        }
                    )
                }
            }

        // Check cancellation and session state after copying.
        do {
            try Task.checkCancellation()

            guard sessions[importedFile.formSessionID]?.isClosing == false else {
                throw JournalFileStorageError.sessionUnavailable
            }

            return prepared

        } catch {
            // Discard the permanent copy if the result is no longer needed.
            discardCopy(
                at: prepared.permanentURL,
                using: fileManager
            )

            throw error
        }
    }

    func removePermanentFile(
        storedFileName: String
    ) throws {

        let url = try validatedPermanentFileURL(
            storedFileName: storedFileName
        )

        try removeIfPresent(
            url,
            using: fileManager
        )
    }
    
    func removePermanentFiles(
        storedFileNames: [String]
    ) {
        for storedFileName in storedFileNames {
            do {
                try removePermanentFile(
                    storedFileName: storedFileName
                )
            } catch {
                logger.error(
                    "Could not remove a journal document: \((error as NSError).code)"
                )
            }
        }
    }

    func fileURL(
        storedFileName: String
    ) throws -> URL {

        try validatedPermanentFileURL(
            storedFileName: storedFileName
        )
    }

    // MARK: - Permanent File URL Validation

    private func validatedPermanentFileURL(
        storedFileName: String
    ) throws -> URL {

        let name = storedFileName as NSString

        let extensionName = name.pathExtension.lowercased()
        let stem = name.deletingPathExtension

        guard storedFileName == name.lastPathComponent,
              ["pdf", "txt"].contains(extensionName),
              let id = UUID(uuidString: stem),
              storedFileName == id.uuidString + "." + extensionName else {

            throw JournalFileStorageError.invalidStoredFileName
        }

        return documentsDirectory.appending(
            path: storedFileName,
            directoryHint: .notDirectory
        )
    }
    
    // MARK: - Launch Recovery

    /// Call once at launch, before any form can import or save documents.
    func recoverAtLaunch(
        referencedFileNames: Set<String>
    ) throws {
        guard sessions.isEmpty else {
            throw JournalFileStorageError.sessionUnavailable
        }

        // Do not clean permanent storage using malformed metadata.
        for name in referencedFileNames {
            _ = try validatedPermanentFileURL(
                storedFileName: name
            )
        }

        try prepareDirectories()

        let documentURLs = try fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [
                .isRegularFileKey,
                .isSymbolicLinkKey
            ]
        )

        for url in documentURLs {
            let name = url.lastPathComponent

            guard !referencedFileNames.contains(name) else {
                continue
            }

            // Ignore files not matching Kairo's document naming format.
            guard (try? validatedPermanentFileURL(
                storedFileName: name
            )) != nil else {
                continue
            }

            let values = try url.resourceValues(
                forKeys: [
                    .isRegularFileKey,
                    .isSymbolicLinkKey
                ]
            )

            guard values.isRegularFile == true,
                  values.isSymbolicLink != true else {
                continue
            }

            try removeIfPresent(url, using: fileManager)
        }

        let sessionURLs = try fileManager.contentsOfDirectory(
            at: stagingDirectory,
            includingPropertiesForKeys: [
                .isDirectoryKey,
                .isSymbolicLinkKey
            ]
        )

        for url in sessionURLs {
            let name = url.lastPathComponent

            guard let id = UUID(uuidString: name),
                  name == id.uuidString else {
                continue
            }

            let values = try url.resourceValues(
                forKeys: [
                    .isDirectoryKey,
                    .isSymbolicLinkKey
                ]
            )

            guard values.isDirectory == true,
                  values.isSymbolicLink != true else {
                continue
            }

            try removeIfPresent(url, using: fileManager)
        }
    }
    
    // MARK: - Blocking File Operations

    private nonisolated func copyToPermanentStorage(
        importedFile: ImportedJournalFile,
        directory: URL
    ) throws -> PreparedJournalFile {

        // Use a file manager local to the background operation.
        let manager = FileManager()

        let source = importedFile.temporaryURL
        let ext = source.pathExtension.lowercased()

        // Determine the supported document type.
        let contentType: UTType

        switch ext {
        case "pdf":
            contentType = .pdf

        case "txt":
            contentType = .plainText

        default:
            throw JournalFileStorageError.unsupportedType
        }

        // Verify that the declared type matches the extension.
        guard importedFile.contentTypeIdentifier == contentType.identifier else {
            throw JournalFileStorageError.unsupportedType
        }

        // Generate a unique permanent filename.
        let storedFileName = UUID().uuidString + "." + ext

        let destination = directory.appending(
            path: storedFileName,
            directoryHint: .notDirectory
        )

        var copyStarted = false

        do {
            // Validate the staged source document.
            _ = try validateFileSize(at: source)

            try validateDocument(
                at: source,
                contentType: contentType
            )

            // Prevent overwriting an existing document.
            guard !manager.fileExists(atPath: destination.path) else {
                throw CocoaError(.fileWriteFileExists)
            }

            // Copy the document.
            copyStarted = true

            try manager.copyItem(
                at: source,
                to: destination
            )

            // Validate the permanent copy.
            let size = try validateFileSize(at: destination)

            try validateDocument(
                at: destination,
                contentType: contentType
            )

            // Return the prepared document metadata.
            return PreparedJournalFile(
                id: importedFile.id,
                displayName: importedFile.displayName,
                storedFileName: storedFileName,
                contentTypeIdentifier: contentType.identifier,
                fileSize: size,
                permanentURL: destination
            )

        } catch {
            // Remove any partial copy after a failed operation.
            if copyStarted {
                discardCopy(
                    at: destination,
                    using: manager
                )
            }

            throw error
        }
    }
    
    private nonisolated func copyToStaging(
        from source: ImportSource,
        directory: URL,
        sessionID: UUID
    ) throws -> ImportedJournalFile {
        let workerFileManager = FileManager()
        let url: URL
        let hasSecurityScope: Bool

        switch source {
        case .filesPicker(let pickedURL):
            guard pickedURL.startAccessingSecurityScopedResource() else {
                throw JournalFileStorageError.accessDenied
            }

            url = pickedURL
            hasSecurityScope = true

        case .appOwned(let localURL):
            url = localURL
            hasSecurityScope = false
        }

        defer {
            if hasSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let ext = url.pathExtension.lowercased()
        let type: UTType

        switch ext {
        case "pdf":
            type = .pdf
        case "txt":
            type = .plainText
        default:
            throw JournalFileStorageError.unsupportedType
        }

        let id = UUID()
        let destination = directory
            .appending(path: id.uuidString, directoryHint: .notDirectory)
            .appendingPathExtension(ext)

        var coordinationError: NSError?
        var copyResult: Result<Void, Error>?
        var copyStarted = false

        do {
            NSFileCoordinator().coordinate(
                readingItemAt: url,
                options: [],
                error: &coordinationError
            ) { readableURL in
                copyResult = Result {
                    _ = try validateFileSize(at: readableURL)

                    guard !workerFileManager.fileExists(
                        atPath: destination.path
                    ) else {
                        throw CocoaError(.fileWriteFileExists)
                    }

                    copyStarted = true

                    try workerFileManager.copyItem(
                        at: readableURL,
                        to: destination
                    )
                }
            }

            if let coordinationError {
                throw coordinationError
            }

            guard let copyResult else {
                throw JournalFileStorageError.fileUnavailable
            }

            try copyResult.get()

            let size = try validateFileSize(at: destination)
            try validateDocument(at: destination, contentType: type)

            return ImportedJournalFile(
                id: id,
                displayName: url.lastPathComponent,
                temporaryURL: destination,
                contentTypeIdentifier: type.identifier,
                fileSize: size,
                formSessionID: sessionID
            )
        } catch {
            if copyStarted {
                discardCopy(at: destination, using: workerFileManager)
            }

            throw error
        }
    }
}
