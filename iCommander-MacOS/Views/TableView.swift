//
//  TableView.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 13/10/2020.
//

import Cocoa

class TableView: NSTableView {
    
    var currentURL: URL = FileManager.default.homeDirectoryForCurrentUser {
        didSet {
            do {
                let fileManager = FileManager.default
                
                let fileURLs = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                
                currentFolderContents = fileURLs
            } catch {
                print("Unexpected error: \(error).")
            }
        }
    }
    var currentFolderContents: [URL] = [] {
        didSet {
            reloadData()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func reloadData() {
        super.reloadData()
        
        if selectedRowIndexes.count == 0 {
            selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        
        if event.keyCode == Constants.KeyCodeEnter {
            currentURL = currentFolderContents[selectedRow]
        } else {
            super.keyDown(with: event)
        }
    }
}
