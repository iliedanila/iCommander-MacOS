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
    func handleF6()
    func handleF7()
    func handleF8()
    func deleteItem(_ tableView: NSTableView, _ row: Int)
    var rowIndexForActivatedMenu: Int { get set }
}

class TableView: NSTableView {
    
    var tableViewDelegate: TableViewDelegate?
    
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
            tableViewDelegate?.deleteItem(self, selectedRow)
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
}
