//
//  TableViewDataSource.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 02/11/2020.
//

import Cocoa

// MARK: - NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let dataSource = tableToDataSource[tableView] {
            return dataSource.tableElements.count
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        let dragOperation: NSDragOperation = []
        
        var isSameTableView: Bool = false
        var isDropOnItem: Bool = false
        var isDropOnDirectory: Bool = false
        
        if let draggingSource = info.draggingSource as? NSTableView {
            isSameTableView = draggingSource == tableView
        }
        
        isDropOnItem = dropOperation == .on
        if isDropOnItem {
            let dataSource = tableToDataSource[tableView]!
            isDropOnDirectory = dataSource.tableElements[row].url.hasDirectoryPath
        }

        if  isDropOnItem && !isDropOnDirectory || isSameTableView {
            return dragOperation
        } else {
            return [.copy]
        }        
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        
        var sourceURLs: [URL] = []
        if let URLs = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) {
            if !URLs.isEmpty {
                for item in URLs {
                    if let url = item as? URL {
                        sourceURLs.append(url)
                    }
                }
            }
        }
        
        print("Drop operation on: \(dropOperation == .on)")
        
        if !sourceURLs.isEmpty {
            let dataSource = tableToDataSource[tableView]!
            
            let destinationURL = dropOperation != .on ? dataSource.currentURL : dataSource.tableElements[row].url
            
            fileOperations.copy(sourceURLs, destinationURL)
        }
        
        return true
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        
        if row == 0 {
            return nil
        }
        
        let dataSource = tableToDataSource[tableView]!
        let draggedItem = dataSource.tableElements[row]
        let itemURL = draggedItem.url
        
        return itemURL as NSURL
    }
}
