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
}

enum Location {
    case Left
    case Right
}

protocol DataSourceDelegate {
    func handlePathChanged(_ dataSource: TableDataSource, _ newUrl: URL)
}

class TableDataSource {
    
    var delegate: DataSourceDelegate?
    var location: Location
    
    init(_ aLocation: Location) {
        location = aLocation
    }
    
    var currentUrl: URL = FileManager.default.homeDirectoryForCurrentUser {
        didSet
        {
            do {
                let fileManager = FileManager.default
                
                let fileURLs = try fileManager.contentsOfDirectory(at: currentUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                
                folderContents = fileURLs
            } catch {
                print("Error while getting folder contents: \(error).")
            }
        }
    }
    
    var folderContents: [URL] = [] {
        didSet {
            tableElements = []
            for url in folderContents {
                let name = url.lastPathComponent
                let isDirectory = url.hasDirectoryPath
                let fileSize = isDirectory ? nil : getFileSize(url)
                let fileSizeString = isDirectory ? "Dir" : ByteCountFormatter().string(fromByteCount: Int64(fileSize!))
                let dateModified = getFileDate(url)
                
                tableElements.append(TableElement(name: name, url: url, size: fileSize, sizeString: fileSizeString, dateModified: dateModified, isDirectory: isDirectory))
            }
            
            delegate?.handlePathChanged(self, currentUrl)
        }
    }
    
    var tableElements: [TableElement] = []
    
    func sort(_ column: String) {
        tableElements.sort { (left, right) -> Bool in
            switch column {
            case Constants.NameColumn:
                if left.isDirectory && right.isDirectory {
                    return left.name < right.name
                } else if left.isDirectory {
                    return true
                } else if right.isDirectory {
                    return false
                } else {
                    return left.name < right.name
                }
            default:
                return left.name < right.name
            }
        }
    }
    
    func getFileSize(_ forURL: URL) -> Int? {
        
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.fileSizeKey])
            return  resourceValues.fileSize //{
        } catch {
            print("Error while getting the file size: \(error)")
            return nil
        }
    }
    
    func getFileDate(_ forURL: URL) -> String {
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
}
