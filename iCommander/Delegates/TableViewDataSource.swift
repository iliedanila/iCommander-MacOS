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
        var dragOperation: NSDragOperation = []
        
        if dropOperation != .on {   // We don't support dropping on an item.
            if let draggingSource = info.draggingSource as? NSTableView {   // Same application
                if draggingSource != tableView {    // Drag and drop within the same table is not supported.
                    dragOperation = [.copy]
                }
            } else {
                dragOperation = [.copy]     // From another application.
            }
        }
        
        return dragOperation
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
        
        if !sourceURLs.isEmpty {
            let dataSource = tableToDataSource[tableView]!
            let destinationURL = dataSource.currentUrl
            
            fileOperations.copy(sourceURLs, destinationURL)
        }
        
        return true
    }
    
    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let dataSource = tableToDataSource[tableView]!
        let draggedItem = dataSource.tableElements[row]
        let itemURL = draggedItem.url
        
        return itemURL as NSURL
    }
}
