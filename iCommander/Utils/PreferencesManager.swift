//
//  PreferencesManager.swift
//  iCommander-MacOS
//
//  Manages app preferences using UserDefaults (simpler than Core Data for this use case)
//

import Foundation

class PreferencesManager {
    
    static let shared = PreferencesManager()
    
    private let defaults = UserDefaults.standard
    
    private enum Keys {
        static let leftPath = "leftCurrentPath"
        static let rightPath = "rightCurrentPath"
        static let leftShowHidden = "leftShowHiddenFiles"
        static let rightShowHidden = "rightShowHiddenFiles"
        static let favoriteURLs = "favoriteURLs"
    }
    
    private init() {}
    
    // MARK: - Left Panel
    
    var leftCurrentPath: URL {
        get {
            if let path = defaults.string(forKey: Keys.leftPath),
               let url = URL(string: path),
               FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            return FileManager.default.homeDirectoryForCurrentUser
        }
        set {
            defaults.set(newValue.absoluteString, forKey: Keys.leftPath)
        }
    }
    
    var leftShowHiddenFiles: Bool {
        get { defaults.bool(forKey: Keys.leftShowHidden) }
        set { defaults.set(newValue, forKey: Keys.leftShowHidden) }
    }
    
    // MARK: - Right Panel
    
    var rightCurrentPath: URL {
        get {
            if let path = defaults.string(forKey: Keys.rightPath),
               let url = URL(string: path),
               FileManager.default.fileExists(atPath: url.path) {
                return url
            }
            return FileManager.default.homeDirectoryForCurrentUser
        }
        set {
            defaults.set(newValue.absoluteString, forKey: Keys.rightPath)
        }
    }
    
    var rightShowHiddenFiles: Bool {
        get { defaults.bool(forKey: Keys.rightShowHidden) }
        set { defaults.set(newValue, forKey: Keys.rightShowHidden) }
    }
    
    // MARK: - Favorites
    
    var favoriteURLs: [URL] {
        get {
            guard let data = defaults.data(forKey: Keys.favoriteURLs),
                  let bookmarks = try? NSKeyedUnarchiver.unarchivedObject(
                    ofClasses: [NSArray.self, NSData.self],
                    from: data
                  ) as? [Data] else {
                return defaultFavorites()
            }
            
            // Resolve bookmarks to URLs
            return bookmarks.compactMap { bookmark in
                var isStale = false
                guard let url = try? URL(
                    resolvingBookmarkData: bookmark,
                    options: .withoutUI,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                ), !isStale else {
                    return nil
                }
                return url
            }
        }
        set {
            // Convert URLs to security-scoped bookmarks
            let bookmarks = newValue.compactMap { url -> Data? in
                try? url.bookmarkData(
                    options: .withSecurityScope,
                    includingResourceValuesForKeys: nil,
                    relativeTo: nil
                )
            }
            
            if let data = try? NSKeyedArchiver.archivedData(
                withRootObject: bookmarks,
                requiringSecureCoding: true
            ) {
                defaults.set(data, forKey: Keys.favoriteURLs)
            }
        }
    }
    
    private func defaultFavorites() -> [URL] {
        return [
            FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask).first,
            FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        ].compactMap { $0 }
    }
    
    // MARK: - Persistence
    
    func save() {
        defaults.synchronize()
    }
}
