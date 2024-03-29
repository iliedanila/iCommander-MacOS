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
                if row == 0 {
                    cell.textField?.isEditable = false
                }
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
}

// MARK: - TableViewDelegate
extension ViewController: TableViewDelegate {
    var tableViewForActivatedMenu: NSTableView? {
        get { return tableViewForContextMenu }
        set { tableViewForContextMenu = newValue }
    }
    
    
    var rowIndexForActivatedMenu: Int {
        get { return rowIndexForContexMenu }
        set { rowIndexForContexMenu = newValue }
    }
    
    
    func refreshDataSource(_ tableView: NSTableView) {
        if let dataSource = tableToDataSource[tableView] {
            dataSource.refreshData()
        }
    }
    
    
    func deleteItems(_ tableView: NSTableView, _ rows: [Int]) {
        if let dataSource = tableToDataSource[tableView] {
            
            var elements: [TableElement] = []
            for row in rows {
                if row != 0 {
                    elements.append(dataSource.tableElements[row])
                }
            }
            
            if elements.isEmpty {
                return
            }
            
            var confirmationString: String = ""
            for element in elements {
                confirmationString += element.name
                confirmationString += "\n"
            }
            
            if showDialog("Are you sure you want to delete \(confirmationString)?") {
                do {
                    for element in elements {
                        try FileManager.default.trashItem(at: element.url, resultingItemURL: nil)
                    }
                    
                    leftTableDataSource.checkPathIsStillValid()
                    rightTableDataSource.checkPathIsStillValid()
                    
                    leftTable.reloadData()
                    rightTable.reloadData()
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
        guard let dataSource = tableToDataSource[tableView] else { return }
        
        if forRow == 0 && urlHasParent(dataSource.currentURL){
            parentFolderRequested(tableView)
            return
        }
        
        let element = dataSource.tableElements[forRow]
        
        if element.isDirectory && !element.isPackage! {
            dataSource.currentURL = element.url
        } else {
            NSWorkspace.shared.open(element.url)
        }
    }
    
    func focusNextTable(_ tableView: NSTableView) {
        if tableView == leftTable {
            // Focus right table
            leftTable.nextKeyView = rightTable
            view.window?.makeFirstResponder(rightTable)
            currentActiveTable = rightTable
            refreshAddRemoveFavButton(tableToDataSource[rightTable]!.currentURL)
        } else {
            // Focus left table
            rightTable.nextKeyView = leftTable
            view.window?.makeFirstResponder(leftTable)
            currentActiveTable = leftTable
            refreshAddRemoveFavButton(tableToDataSource[leftTable]!.currentURL)
        }
    }
    
    func urlHasParent(_ url: URL) -> Bool {
        let parentUrl = url.deletingLastPathComponent()
        let currentPath = url.path
        let parentPath = parentUrl.path
        if !FileManager.default.contentsEqual(atPath: currentPath, andPath: parentPath) {
            return true
        }
        return false
    }
    
    func parentFolderRequested(_ tableView: NSTableView) {
        if let tableData = tableToDataSource[tableView] {
            let previousDirectory = tableData.currentURL
            let parentUrl = tableData.currentURL.deletingLastPathComponent()
            
            if !FileManager.default.contentsEqual(atPath: previousDirectory.path, andPath: parentUrl.path) {
                tableData.currentURL = parentUrl
            }
            
            if let index = tableData.tableElements.firstIndex(where: { (element) -> Bool in
                return element.url == previousDirectory
            }) {
                tableView.selectRowIndexes([index], byExtendingSelection: false)
            }
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
    
    func handleF5() {
        if let sourceTable = currentActiveTable {
            let destinationTable = sourceTable == leftTable ? rightTable : leftTable
            let dataSource = tableToDataSource[sourceTable]!
            var sourceItems: [URL] = []
            
            for selectedRowIndex in sourceTable.selectedRowIndexes {
                sourceItems.append(dataSource.tableElements[selectedRowIndex].url)
            }
            let destinationFolderUrl = tableToDataSource[destinationTable!]!.currentURL
            
            fileOperations.copy(sourceItems, destinationFolderUrl)
            
            leftTable.reloadData()
            rightTable.reloadData()
        }
    }
    
    func handleF6() {
        guard let sourceTable = currentActiveTable else { return }
        let destinationTable = sourceTable == leftTable ? rightTable : leftTable
        let dataSource = tableToDataSource[sourceTable]!
        
        var sourceItems: [TableElement] = []
        for index in sourceTable.selectedRowIndexes {
            sourceItems.append(dataSource.tableElements[index])
        }

        let destinationFolderUrl = tableToDataSource[destinationTable!]!.currentURL
        
        fileOperations.move(sourceItems, destinationFolderUrl)
    }
    
    func getNewFolderName() -> String {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "New Folder's Name:"
        alert.icon = nil
        
        alert.addButton(withTitle: "Ok")
        alert.addButton(withTitle: "Cancel")
        let windowWidth = alert.window.contentLayoutRect.width
        let windowHeight = alert.window.contentLayoutRect.height
        
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight / 13))
        alert.window.initialFirstResponder = textField
        textField.placeholderString = ""
        alert.accessoryView = textField
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            return textField.stringValue
        }
        return ""
    }
    
    func createFolder(_ tableView: NSTableView, _ folderName: String) {
        let dataSource = tableToDataSource[tableView]!
        let parentFolder = dataSource.currentURL
        
        do {
            try FileManager.default.createDirectory(at: parentFolder.appendingPathComponent(folderName), withIntermediateDirectories: false, attributes: nil)
        } catch {
            print("Error in creating new folder: \(error)")
        }
    }
    
    func handleF7() {
        let newFolderName = getNewFolderName()
        guard let sourceTable = currentActiveTable else { return }
        createFolder(sourceTable, newFolderName)
        
        leftTable.reloadData()
        rightTable.reloadData()
    }
    
    func handleF8() {
        guard let sourceTable = currentActiveTable else { return }
        deleteItems(sourceTable, Array(sourceTable.selectedRowIndexes))
    }
}
