//
//  ViewController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 29/09/2020.
//

import Cocoa

// MARK: - NSViewController

class ViewController: NSViewController {

    @IBOutlet var leftTable: NSTableView!
    @IBOutlet var rightTable: NSTableView!
    @IBOutlet var leftUpButton: NSButton!
    @IBOutlet var rightUpButton: NSButton!
    @IBOutlet var tableMenu: NSMenu!
    @IBOutlet var leftPathStackView: NSStackView!
    @IBOutlet var rightPathStackView: NSStackView!
    @IBOutlet var leftHomeButton: NSButton!
    @IBOutlet var rightHomeButton: NSButton!
    @IBOutlet var F3ViewButton: NSButton!
    @IBOutlet var F4EditButton: NSButton!
    @IBOutlet var F5CopyButton: NSButton!
    @IBOutlet var F6MoveButton: NSButton!
    @IBOutlet var F7NewFolderButton: NSButton!
    @IBOutlet var F8DeleteButton: NSButton!
    @IBOutlet var leftDriveButton: NSPopUpButton!
    @IBOutlet var rightDriveButton: NSPopUpButton!
    
    var tableToPath: [NSTableView : NSStackView] = [:]
    var rowIndexForMenu: Int? = nil
    var leftTableDataSource: TableDataSource = TableDataSource(.Left)
    var rightTableDataSource: TableDataSource = TableDataSource(.Right)
    var tableToDataSource: [NSTableView : TableDataSource] = [:]
    var indexDrivePath: [Int : URL] = [:]
    var lastSelectedRow: [NSTableView : Int] = [:]
    
    @IBAction func handleDriveButton(_ sender: NSPopUpButton) {
        if sender == leftDriveButton {
            leftTableDataSource.currentUrl = indexDrivePath[sender.indexOfSelectedItem]!
        } else {
            rightTableDataSource.currentUrl = indexDrivePath[sender.indexOfSelectedItem]!
        }
    }
    
    @IBAction func tableClicked(_ sender: NSTableView) {
        if sender.clickedRow == -1 && sender.clickedColumn != -1 {
            if let tableData = tableToDataSource[sender] {
                print("Sort descriptor count: \(sender.sortDescriptors.count)")
                let sortDescriptor = sender.sortDescriptors[0]
                if let key = sortDescriptor.key {
                    print("Sort - Key: \(key) ascending: \(sortDescriptor.ascending)")
                    tableData.sort(key, sortDescriptor.ascending)
                }
                sender.reloadData()
            }
        }
    }
    
    @IBAction func tableDoubleClick(_ sender: NSTableView) {
        if sender.clickedRow == -1 {
            return
        }
        
        if let tableData = tableToDataSource[sender] {
            let itemURL = tableData.tableElements[sender.clickedRow].url
            if itemURL.hasDirectoryPath {
                tableData.currentUrl = itemURL
            } else {
                NSWorkspace.shared.open(itemURL)
            }
        }
    }
    
    @IBAction func leftUpClicked(_ sender: NSButton) {
        if let tableData = tableToDataSource[leftTable] {
            let parentUrl = tableData.currentUrl.deletingLastPathComponent()
            tableData.currentUrl = parentUrl
        }
    }
    
    @IBAction func rightUpClicked(_ sender: NSButton) {
        if let tableData = tableToDataSource[rightTable] {
            let parentUrl = tableData.currentUrl.deletingLastPathComponent()
            tableData.currentUrl = parentUrl
        }
    }
    
    @IBAction func homeButtonClicked(_ sender: NSButton) {
        if sender == leftHomeButton {
            leftTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        } else {
            rightTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableToPath[leftTable] = leftPathStackView
        tableToPath[rightTable] = rightPathStackView
        tableToDataSource[leftTable] = leftTableDataSource
        tableToDataSource[rightTable] = rightTableDataSource
        
        leftTableDataSource.delegate = self
        rightTableDataSource.delegate = self
        lastSelectedRow[leftTable] = 0
        lastSelectedRow[rightTable] = 0
        
        leftTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        rightTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        
        if let leftTableView = leftTable as? TableView, let rightTableView = rightTable as? TableView {
            leftTableView.tableViewDelegate = self
            rightTableView.tableViewDelegate = self
            
            leftTableDataSource.sort(Constants.NameColumn, true)
            rightTableDataSource.sort(Constants.NameColumn, true)

            leftTable.reloadData()
            rightTable.reloadData()
        }
        
        leftTable.rowSizeStyle = .medium
        rightTable.rowSizeStyle = .medium
        
        populateDriveList()
                
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(handleDriveChange), name: NSWorkspace.didMountNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleDriveChange), name: NSWorkspace.didUnmountNotification, object: nil)
    }
    
    func populateDriveList() {
        leftDriveButton.removeAllItems()
        rightDriveButton.removeAllItems()
        indexDrivePath.removeAll()
        
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: [.skipHiddenVolumes]) {
            
            var index: Int = 0
            for mountedVolume in mountedVolumes {
                leftDriveButton.addItem(withTitle: mountedVolume.lastPathComponent)
                rightDriveButton.addItem(withTitle: mountedVolume.lastPathComponent)
                indexDrivePath[index] = mountedVolume
                index = index + 1
            }
        }
    }

    func handleMaximize() {
        resizeTableViewColumns(leftTable)
        resizeTableViewColumns(rightTable)
    }
    
    func resizeTableViewColumns(_ tableView: NSTableView) {
        var tableWidth: CGFloat = 0
        for column in tableView.tableColumns {
            tableWidth = tableWidth + column.width
        }
        
        tableView.tableColumns[0].width = 5 * tableWidth / 8
        tableView.tableColumns[1].width = 2 * tableWidth / 8
        tableView.tableColumns[2].width = tableWidth / 8
        
        tableView.needsDisplay = true
    }
    
    @objc func handleDriveChange(_ notification: NSNotification) {
        populateDriveList()
    }
}

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
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let dataSource = tableToDataSource[tableView] {
            return dataSource.tableElements.count
        }
        return 0
    }
}

// MARK: - TableViewDelegate
extension ViewController: TableViewDelegate {
    func deleteItem(_ tableView: NSTableView, _ row: Int) {
        if let dataSource = tableToDataSource[tableView] {
            let element = dataSource.tableElements[row]
            
            if dialogOkCancel("Are you sure you want to delete \(element.name)?") {
                do {
                    try FileManager.default.trashItem(at: element.url, resultingItemURL: nil)
                    tableView.reloadData()
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func dialogOkCancel(_ text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = text
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    var rowForMenu: Int? {
        get {
            return self.rowIndexForMenu
        }
        set {
            self.rowIndexForMenu = newValue
        }
    }
    
    func handleEnterPressed(_ tableView: NSTableView, _ forRow: Int) {
        if let dataSource = tableToDataSource[tableView] {
            let element = dataSource.tableElements[forRow]
            
            if element.isDirectory {
                dataSource.currentUrl = element.url
            } else {
                NSWorkspace.shared.open(element.url)
            }
        }
    }
    
    func focusNextTable(_ tableView: NSTableView) {
        if tableView == leftTable {
            // Focus right table
            leftTable.nextKeyView = rightTable
            refreshButtonsState(rightTable, rightTable.selectedRow)
        } else {
            // Focus left table
            rightTable.nextKeyView = leftTable
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
            if tableView.selectedRow == -1 {
                if tableView.selectedColumn == -1 {
                    let rowIndex = lastSelectedRow[tableView]!
                    tableView.selectRowIndexes([rowIndex], byExtendingSelection: false)
                }
                return
            }
            
            lastSelectedRow[tableView] = tableView.selectedRow
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

// MARK: - NSMenuDelegate
extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(withTitle: "1st menu item", action: #selector(doNothing), keyEquivalent: "")
        menu.addItem(withTitle: "2nd menu item", action: #selector(doNothing), keyEquivalent: "")
    }
    
    @objc func doNothing() {
    }
}

// MARK: - TextFieldDelegate
extension ViewController: TextFieldDelegate {
    func pathRequested(_ textField: NSTextField, _ path: URL?, _ tableView: NSTableView?) {
        
        if let nsTableView = tableView, let tableData = tableToDataSource[nsTableView] {
            if let newUrl = path {
                tableData.currentUrl = newUrl
//                nsTableView.reloadData()
            }
        }        
    }
}

// MARK: - DataSourceDelegate
extension ViewController: DataSourceDelegate {
    func handlePathChanged(_ dataSource: TableDataSource, _ newUrl: URL) {
        
        let tableView = dataSource.location == .Left ? leftTable : rightTable        
        if let stackView = dataSource.location == .Left ? leftPathStackView : rightPathStackView {
            let views = stackView.arrangedSubviews
            for view in views {
                stackView.removeView(view)
            }
            
            let firstTextField = NSTextField()
            setupTextField(firstTextField, Constants.CurrentPath)
            stackView.insertView(firstTextField, at: 0, in: .leading)

            var pathComponents = newUrl.pathComponents
            for index in 1..<pathComponents.count {
                pathComponents[index] = pathComponents[index] + "/"
            }
            
            var currentPath = ""
            for index in 0..<pathComponents.count {
                currentPath = currentPath + pathComponents[index]
                let currentUrl = URL(fileURLWithPath: currentPath)
                
                let textField = TextField()
                setupTextField(textField, pathComponents[index])
                textField.textFieldDelegate = self
                textField.path = currentUrl
                textField.tableViewAssociated = tableView
                stackView.insertView(textField, at: index + 1, in: .leading)
            }
        }
        tableView?.reloadData()
    }
}
