//
//  FileManagerService.swift
//  iCommander-MacOS
//
//  Architecture improvement: Centralized file management service
//

import Foundation
import Cocoa

/// Result type for file operations
enum FileOperationResult {
    case success
    case failure(Error)
    case cancelled
}

/// Service class to handle all file system operations
/// Separates business logic from UI
class FileManagerService {
    
    static let shared = FileManagerService()
    
    private let fileManager = FileManager.default
    
    private init() {}
    
    // MARK: - File Information
    
    func contentsOfDirectory(at url: URL, showHidden: Bool) -> Result<[TableElement], Error> {
        do {
            var options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants]
            if !showHidden {
                options.insert(.skipsHiddenFiles)
            }
            
            let urls = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isPackageKey],
                options: options
            )
            
            let elements = urls.compactMap { url -> TableElement? in
                guard let name = url.lastPathComponent as String?,
                      let isDirectory = url.hasDirectoryPath as Bool? else {
                    return nil
                }
                
                let fileSize = isDirectory ? nil : getFileSize(url)
                let sizeString = isDirectory ? "Dir" : ByteCountFormatter().string(fromByteCount: Int64(fileSize ?? 0))
                let dateModified = getFileModifiedDate(url)
                let isPackage = getIsPackage(url)
                
                return TableElement(
                    name: name,
                    url: url,
                    size: fileSize,
                    sizeString: sizeString,
                    dateModified: dateModified,
                    isDirectory: isDirectory,
                    volumeID: getVolumeID(url),
                    isPackage: isPackage
                )
            }
            
            return .success(elements)
        } catch {
            return .failure(error)
        }
    }
    
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    // MARK: - File Operations
    
    func createDirectory(at url: URL) -> FileOperationResult {
        do {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: false, attributes: nil)
            return .success
        } catch {
            return .failure(error)
        }
    }
    
    func deleteItems(_ items: [TableElement]) -> FileOperationResult {
        do {
            for item in items {
                try fileManager.trashItem(at: item.url, resultingItemURL: nil)
            }
            return .success
        } catch {
            return .failure(error)
        }
    }
    
    func rename(_ url: URL, to newName: String) -> FileOperationResult {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: url, to: newURL)
            return .success
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getFileSize(_ url: URL) -> Int? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            return resourceValues.fileSize
        } catch {
            NSLog("Error getting file size for \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func getFileModifiedDate(_ url: URL) -> String {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.contentModificationDateKey])
            if let date = resourceValues.contentModificationDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                return formatter.string(from: date)
            }
        } catch {
            NSLog("Error getting modification date for \(url.lastPathComponent): \(error)")
        }
        return ""
    }
    
    private func getIsPackage(_ url: URL) -> Bool? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isPackageKey])
            return resourceValues.isPackage
        } catch {
            NSLog("Error checking if package for \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    private func getVolumeID(_ url: URL) -> Any? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.volumeIdentifierKey])
            return resourceValues.volumeIdentifier
        } catch {
            NSLog("Error getting volume ID for \(url.lastPathComponent): \(error)")
            return nil
        }
    }
}
