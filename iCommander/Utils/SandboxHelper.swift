//
//  SandboxHelper.swift
//  iCommander-MacOS
//
//  Helper for App Sandbox file access
//

import Cocoa

class SandboxHelper {
    
    static let shared = SandboxHelper()
    
    private init() {}
    
    /// Request access to a folder from the user
    func requestFolderAccess(message: String = "Please grant access to browse files") -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.message = message
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        
        if openPanel.runModal() == .OK {
            return openPanel.url
        }
        return nil
    }
    
    /// Create a security-scoped bookmark for persistent access
    func createBookmark(for url: URL) -> Data? {
        do {
            let bookmark = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            return bookmark
        } catch {
            AppLogger.error("Failed to create bookmark: \(error)", category: .fileOperations)
            return nil
        }
    }
    
    /// Resolve a security-scoped bookmark
    func resolveBookmark(_ bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                AppLogger.info("Bookmark is stale, needs refresh", category: .fileOperations)
            }
            
            return url
        } catch {
            AppLogger.error("Failed to resolve bookmark: \(error)", category: .fileOperations)
            return nil
        }
    }
    
    /// Start accessing a security-scoped resource
    func startAccessingSecurityScopedResource(_ url: URL) -> Bool {
        return url.startAccessingSecurityScopedResource()
    }
    
    /// Stop accessing a security-scoped resource
    func stopAccessingSecurityScopedResource(_ url: URL) {
        url.stopAccessingSecurityScopedResource()
    }
}
