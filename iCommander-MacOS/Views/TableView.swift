//
//  TableView.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 13/10/2020.
//

import Cocoa

protocol TableViewDelegate {
    var rowForMenu: Int? { get set }
    func goToParent(_ tableView: NSTableView)
    func focusNextTable(_ tableView: NSTableView)
    func currentPathChanged(_ tableView: NSTableView, _ path: URL)
    func handleEnterPressed(_ forRow: Int)
}

class TableView: NSTableView {
    
    var tableViewDelegate: TableViewDelegate?
    
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
            tableViewDelegate?.handleEnterPressed(selectedRow)
        } else if
            event.keyCode == Constants.KeyCodeDelete ||
            event.keyCode == Constants.KeyCodeUp && event.modifierFlags.contains(.command) {
                tableViewDelegate?.goToParent(self)
        } else if event.keyCode == Constants.KeyCodetab {
            tableViewDelegate?.focusNextTable(self)
            super.keyDown(with: event)
        } else {
            print("\(event.keyCode) has been pressed.")
            super.keyDown(with: event)
        }
    }
    
    override func menu(for event: NSEvent) -> NSMenu? {
        let pointInView = convert(event.locationInWindow, from: nil)
        let rowforMenu = row(at: pointInView)
        
        tableViewDelegate?.rowForMenu = rowforMenu
        
        return super.menu(for: event)
    }
}
