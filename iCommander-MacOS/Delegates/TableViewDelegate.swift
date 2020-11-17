//
//  TableViewDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 02/11/2020.
//

import Cocoa

// MARK: - NSTableViewDelegate
extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let identifier = NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier.rawValue)!)
        
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            
            let dataSource = tableToDataSource[tableView]
            let element = dataSource!.tableElements[row]
            switch tableColumn?.title {
            case Constants.NameColumn:
                cell.textField?.stringValue = element.name
                cell.imageView?.image = NSWorkspace.shared.icon(forFile: element.url.path)
            case Constants.SizeColumn:
                cell.textField?.stringValue = element.sizeString
            case Constants.DateColumn:
                cell.textField?.stringValue = element.dateModified
            default:
                print("Column not recognized")
            }
            
            return cell
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return tableView.visibleRect.width / 32
    }
}

// MARK: - TableViewDelegate
extension ViewController: TableViewDelegate {
    func deleteItem(_ tableView: NSTableView, _ row: Int) {
        if let dataSource = tableToDataSource[tableView] {
            let element = dataSource.tableElements[row]
            
            if showDialog("Are you sure you want to delete \(element.name)?") {
                do {
                    try FileManager.default.trashItem(at: element.url, resultingItemURL: nil)
                    tableView.reloadData()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func showDialog(_ text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    func handleEnterPressed(_ tableView: NSTableView, _ forRow: Int) {
        if forRow == -1 {
            return
        }
        
        if let dataSource = tableToDataSource[tableView], let locationHistory = tableToLocationHistory[tableView] {
            let element = dataSource.tableElements[forRow]
            
            if element.isDirectory {
                dataSource.currentUrl = element.url
                locationHistory.addDirectoryToHistory(element.url)
                
            } else {
                NSWorkspace.shared.open(element.url)
            }
        }
    }
    
    func focusNextTable(_ tableView: NSTableView) {
        if tableView == leftTable {
            // Focus right table
            leftTable.nextKeyView = rightTable
            currentActiveTable = rightTable
            refreshButtonsState(rightTable, rightTable.selectedRow)
        } else {
            // Focus left table
            rightTable.nextKeyView = leftTable
            currentActiveTable = leftTable
            refreshButtonsState(leftTable, leftTable.selectedRow)
        }
    }
    
    func goToParent(_ tableView: NSTableView) {
        if let tableData = tableToDataSource[tableView] {
            let parentUrl = tableData.currentUrl.deletingLastPathComponent()
            tableData.currentUrl = parentUrl
        }
    }
    
    func setupTextField(_ textField: NSTextField, _ stringValue: String) {
        textField.stringValue = stringValue
        textField.isEditable = false
        textField.isSelectable = false
        textField.isBezeled = false
        textField.isBordered = false
        textField.backgroundColor = .none
        textField.drawsBackground = false
        textField.isEnabled = true
        let fontName = textField.font?.fontName ?? ""
        textField.font = NSFont(name: fontName, size: 15)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let tableView = notification.object as? NSTableView {
            refreshButtonsState(tableView, tableView.selectedRow)
        }
    }
    
    func refreshButtonsState(_ tableView: NSTableView, _ row: Int) {
        if tableView.selectedRow == -1 {
            return
        }
        
        let dataSource = tableToDataSource[tableView]
        
        if let element = dataSource?.tableElements[tableView.selectedRow] {
            switch element.isDirectory {
            case true:
                F3ViewButton.isEnabled = false
                F4EditButton.isEnabled = false
                F5CopyButton.isEnabled = true
                F6MoveButton.isEnabled = true
                F7NewFolderButton.isEnabled = true
                F8DeleteButton.isEnabled = true
            case false:
                F3ViewButton.isEnabled = true
                F4EditButton.isEnabled = true
                F5CopyButton.isEnabled = true
                F6MoveButton.isEnabled = true
                F7NewFolderButton.isEnabled = true
                F8DeleteButton.isEnabled = true
            }
        }
    }
}
