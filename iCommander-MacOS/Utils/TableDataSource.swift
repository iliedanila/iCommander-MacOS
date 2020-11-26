//
//  TableDataSource.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 20/10/2020.
//

import Foundation
//import Cocoa

struct TableElement {
    let name: String
    let url: URL
    let size: Int?
    let sizeString: String
    let dateModified: String
    let isDirectory: Bool
    let volumeID: Any?
    let isPackage: Bool?
}

protocol DataSourceDelegate {
    func handlePathChanged(_ dataSource: TableDataSource, _ newUrl: URL)
}

class TableDataSource {
    
    var delegate: DataSourceDelegate?
    var location: LocationOnScreen
    var sortColumn: String? = nil
    var isAscending: Bool? = nil
    var tableElements: [TableElement] = []
    
    init(_ aLocation: LocationOnScreen) {
        location = aLocation
    }
    
    var currentUrl: URL = FileManager.default.homeDirectoryForCurrentUser {
        didSet
        {
            refreshData()
            
            delegate?.handlePathChanged(self, currentUrl)
        }
    }
    
    func refreshData() {
        
        tableElements = []
        addParentFolder(currentUrl)
        addFolderContents(currentUrl)
        
        if let column = sortColumn, let ascending = isAscending {
            sort(column, ascending)
        }
    }
    
    func addParentFolder(_ url: URL) {
        let parentUrl = url.deletingLastPathComponent()
        
        if !FileManager.default.contentsEqual(atPath: url.path, andPath: parentUrl.path) {
            let name = ".."
            let fileSize: Int? = nil
            let fileSizeString = "Dir"
            let dateModified = getFileModifiedDate(parentUrl)
            
            tableElements.append(
                TableElement(
                    name: name,
                    url: parentUrl,
                    size: fileSize,
                    sizeString: fileSizeString,
                    dateModified: dateModified,
                    isDirectory: true,
                    volumeID: getVolumeID(parentUrl),
                    isPackage: false))
        }
    }
    
    func addFolderContents(_ url: URL) {
        do {
            let fileManager = FileManager.default
            
            let fileURLs = try fileManager.contentsOfDirectory(at: currentUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            
            
            for url in fileURLs {
                let name = url.lastPathComponent
                let isDirectory = url.hasDirectoryPath
                let fileSize = isDirectory ? nil : getFileSize(url)
                let fileSizeString = isDirectory ? "Dir" : ByteCountFormatter().string(fromByteCount: Int64(fileSize!))
                let dateModified = getFileModifiedDate(url)
                let isPackage = getIsPackage(url)
                
                tableElements.append(
                    TableElement(
                        name: name,
                        url: url,
                        size: fileSize,
                        sizeString: fileSizeString,
                        dateModified: dateModified,
                        isDirectory: isDirectory,
                        volumeID: getVolumeID(url),
                        isPackage: isPackage))
            }
        } catch {
            print("Error while getting folder contents: \(error).")
        }
    }
    
    func getVolumeID(_ forURL: URL) -> Any? {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.volumeIdentifierKey])
            return  resourceValues.volumeIdentifier
        } catch {
            print("Error retrieving volume ID: \(error)")
            return nil
        }
    }
    
    func getFileSize(_ forURL: URL) -> Int? {
        
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.fileSizeKey])
            return  resourceValues.fileSize
        } catch {
            print("Error while getting the file size: \(error)")
            return nil
        }
    }
    
    func getIsPackage(_ forURL: URL) -> Bool? {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.isPackageKey])
            return  resourceValues.isPackage
        } catch {
            print("Error while getting resource value isPackage: \(error)")
            return nil
        }
    }
    
    func getFileModifiedDate(_ forURL: URL) -> String {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.contentModificationDateKey])
            if let dateModified = resourceValues.contentModificationDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
                let dateString = dateFormatter.string(from: dateModified)
                return dateString
            }
        } catch {
            print("Error while getting file date: \(error)")
        }
        return ""
    }
    
    func sort(_ column: String, _ ascending: Bool) {
        sortColumn = column
        isAscending = ascending
        
        tableElements.sort { (left, right) -> Bool in
            
            if left.name == ".." {
                return true
            }
            if right.name == ".." {
                return false
            }
            
            switch column {
            case Constants.NameColumn:
                if left.isDirectory && right.isDirectory ||
                    !left.isDirectory && !right.isDirectory {
                    return lesser(left.name, right.name, ascending)
                } else if left.isDirectory {
                    return true
                } else {
                    return false
                }
                
            case Constants.SizeColumn:
                if let leftSize = left.size, let rightSize = right.size {
                    return lesser(leftSize, rightSize, ascending) // (file ? file)
                } else if left.isDirectory && right.isDirectory {
                    return lesser(left.name, right.name, ascending) // (folder ? folder)
                } else if left.isDirectory {
                    return true // (directory ? file)
                } else {
                    return false // (file ? directory)
                }
                
            case Constants.DateColumn:
                return lesser(left.dateModified, right.dateModified, ascending)
                
            default:
                return left.name < right.name
            }
        }
    }
    
    func lesser<T: Comparable>(_ first: T, _ second: T, _ ascending: Bool) -> Bool {
        if ascending {
            return first < second
        } else {
            return first > second
        }
    }
}
