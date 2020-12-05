//
//  TableView.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 13/10/2020.
//

import Cocoa

protocol TableViewDelegate {
    func parentFolderRequested(_ tableView: NSTableView)
    func refreshDataSource(_ tableView: NSTableView)
    func focusNextTable(_ tableView: NSTableView)
    func handleEnterPressed(_ tableView: NSTableView, _ row: Int)
    func handleF5()
    func dragAndDropCopy(_ tableView: NSTableView, _ url: URL)
    func handleF6()
    func handleF7()
    func handleF8()
    func deleteItems(_ tableView: NSTableView, _ rows: [Int])
    var rowIndexForActivatedMenu: Int { get set }
}

class TableView: NSTableView {
    
    var tableViewDelegate: TableViewDelegate?
    let supportedTypes: [NSPasteboard.PasteboardType] = [.fileURL]
    
    override func awakeFromNib() {
        registerForDraggedTypes(supportedTypes)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func reloadData() {
        tableViewDelegate?.refreshDataSource(self)
        
        super.reloadData()
        
        if selectedRowIndexes.count == 0 {
            selectRowIndexes([0], byExtendingSelection: false)
        }
    }
    
    override func keyDown(with event: NSEvent) {
        
        if event.keyCode == Constants.KeyCodeEnter {
            tableViewDelegate?.handleEnterPressed(self, selectedRow)
        } else if event.keyCode == Constants.KeyCodeUp && event.modifierFlags.contains(.command) {
                tableViewDelegate?.parentFolderRequested(self)
        } else if event.keyCode == Constants.KeyCodetab {
            tableViewDelegate?.focusNextTable(self)
            super.keyDown(with: event)
        } else if event.keyCode == Constants.KeyCodeDelete && event.modifierFlags.contains(.command){
            tableViewDelegate?.deleteItems(self, Array(selectedRowIndexes))
        } else if event.keyCode == Constants.KeyCodeR && event.modifierFlags.contains(.command){
            reloadData()
        } else if event.keyCode == Constants.KeyCodeF5 {
            tableViewDelegate?.handleF5()
        } else if event.keyCode == Constants.KeyCodeF6 {
            tableViewDelegate?.handleF6()
        } else if event.keyCode == Constants.KeyCodeF7 {
            tableViewDelegate?.handleF7()
        } else if event.keyCode == Constants.KeyCodeF8 {
            tableViewDelegate?.handleF8()
        } else {
            print("Key down: \(event.keyCode)")
            super.keyDown(with: event)
        }
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let pointInView = convert(event.locationInWindow, from: nil)
        let rowforMenu = row(at: pointInView)
        tableViewDelegate?.rowIndexForActivatedMenu = rowforMenu
        
        return super.menu(for: event)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let canReadPasteboardObjects = sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly : true])
        
        if canReadPasteboardObjects {
            highlight()
            return .copy
        }
        return NSDragOperation()
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return draggingEntered(sender)
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("performDragOperation")
        guard let pasteboardObjects = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil), pasteboardObjects.count > 0 else { return false }
        
        pasteboardObjects.forEach { (object) in
            if let url = object as? NSURL {
                self.tableViewDelegate?.dragAndDropCopy(self, url as URL)
            }
        }
        
        return true
    }
    
    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        print("concludeDragOperation")
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        unhighlight()
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        unhighlight()
    }
    
    func highlight() {
        self.layer?.borderColor = NSColor.controlAccentColor.cgColor
        self.layer?.borderWidth = 2.0
    }
    
    func unhighlight() {
        self.layer?.borderColor = NSColor.clear.cgColor
        self.layer?.borderWidth = 0.0
    }
}
