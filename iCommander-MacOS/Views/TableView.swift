//
//  TableView.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 13/10/2020.
//

import Cocoa

protocol TableViewDelegate {
    func goToParent(_ tableView: NSTableView)
    func currentPathChanged(_ tableView: NSTableView, _ path: String)
}

class TableView: NSTableView {
    
    var tableViewDelegate: TableViewDelegate?
    
    var currentURL: URL = FileManager.default.homeDirectoryForCurrentUser {
        didSet {
            do {
                let fileManager = FileManager.default
                
                let fileURLs = try fileManager.contentsOfDirectory(at: currentURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
                
                currentFolderContents = fileURLs
                
                tableViewDelegate?.currentPathChanged(self, currentURL.path)
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
            let itemUrl = currentFolderContents[selectedRow]
            if itemUrl.hasDirectoryPath {
                currentURL = itemUrl
            } else {
                NSWorkspace.shared.open(itemUrl)
            }
        } else if
            event.keyCode == Constants.KeyCodeDelete ||
            event.keyCode == Constants.KeyCodeUp && event.modifierFlags.contains(.command) {
                tableViewDelegate?.goToParent(self)
        } else {
            super.keyDown(with: event)
        }
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let pointInView = convert(event.locationInWindow, from: nil)
        let identifierString = identifier?.rawValue ?? ""
        print("\(identifierString) - Row right-clicked: \(row(at: pointInView))")
        let isDirectory = currentFolderContents[row(at: pointInView)].hasDirectoryPath
        
        if isDirectory {
            print("is a folder")
        } else {
            print("is a file")
        }
        
        return nil
    }
}
