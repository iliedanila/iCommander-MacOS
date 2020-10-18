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
    
    var tableToPath: [NSTableView : NSStackView] = [:]
    var urlRightClicked: URL? = nil
    
    @IBAction func tableDoubleClick(_ sender: NSTableView) {
        if sender.clickedRow == -1 {
            return
        }
        
        if let myTableView = sender as? TableView {
            let itemURL = myTableView.currentFolderContents[sender.clickedRow]
            
            if itemURL.hasDirectoryPath {
                myTableView.currentURL = itemURL
            }
        }
    }
    
    @IBAction func leftUpClicked(_ sender: NSButton) {
        if let myTableView = leftTable as? TableView {
            let parentUrl = myTableView.currentURL.deletingLastPathComponent()
            myTableView.currentURL = parentUrl
        }
    }
    
    @IBAction func rightUpClicked(_ sender: NSButton) {
        if let myTableView = rightTable as? TableView {
            let parentUrl = myTableView.currentURL.deletingLastPathComponent()
            myTableView.currentURL = parentUrl
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableToPath[leftTable] = leftPathStackView
        tableToPath[rightTable] = rightPathStackView
        
        if let leftTableView = leftTable as? TableView, let rightTableView = rightTable as? TableView {
            leftTableView.currentURL = FileManager.default.homeDirectoryForCurrentUser
            rightTableView.currentURL = FileManager.default.homeDirectoryForCurrentUser
            leftTableView.tableViewDelegate = self
            rightTableView.tableViewDelegate = self
            
            currentPathChanged(leftTable, FileManager.default.homeDirectoryForCurrentUser)
            currentPathChanged(rightTable, FileManager.default.homeDirectoryForCurrentUser)
            
            print(leftTable.tableColumns[0].width)
            print(leftTable.tableColumns[1].width)
            print(leftTable.tableColumns[2].width)
        }
        
        leftTable.rowSizeStyle = .medium
        rightTable.rowSizeStyle = .medium        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let identifier = NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier.rawValue)!)
        
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            
            if let myTableView = tableView as? TableView {
                let url = myTableView.currentFolderContents[row]
                
                switch tableColumn?.title {
                case Constants.NameColumn:
                    let icon = NSWorkspace.shared.icon(forFile: url.path)
                    let name = url.lastPathComponent
                    cell.textField?.stringValue = name
                    cell.imageView?.image = icon
                case Constants.SizeColumn:
                    cell.textField?.stringValue = getFileSize(url)
                case Constants.DateColumn:
                    cell.textField?.stringValue = getFileDate(url)
                default:
                    print("Column not recognized")
                }
                
                
                return cell
            }
        }
        return nil
    }
    
    func getFileSize(_ forURL: URL) -> String {
        
        if forURL.hasDirectoryPath {
            return "DIR"
        }
        
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.fileSizeKey])
            if let filesize = resourceValues.fileSize {
                let size = ByteCountFormatter().string(fromByteCount: Int64(filesize))
                return size
            }
        } catch {
            print(error)
        }
        return ""
    }
    
    func getFileDate(_ forURL: URL) -> String {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.contentModificationDateKey])
            if let dateModified = resourceValues.contentModificationDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
                let dateString = dateFormatter.string(from: dateModified)
                return dateString
            }
        } catch {
            print(error)
        }
        return ""
    }
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let myTableView = tableView as? TableView {
            return myTableView.currentFolderContents.count
        }
        return 0
    }
}

// MARK: - TableViewDelegate
extension ViewController: TableViewDelegate {
    func focusNextTable(_ tableView: NSTableView) {
        if tableView == leftTable {
            // Focus right table
        } else {
            // Focus left table
        }
    }
    
    var urlMenu: URL? {
        get {
            return urlRightClicked
        }
        set {
            urlRightClicked = newValue
        }
    }
    
    func currentPathChanged(_ tableView: NSTableView, _ path: URL) {
        let currentStackView = tableToPath[tableView]!
        let views = currentStackView.arrangedSubviews
        for view in views {
            currentStackView.removeView(view)
        }
        
        let firstTextField = NSTextField()
        setupTextField(firstTextField, Constants.CurrentPath)
        currentStackView.insertView(firstTextField, at: 0, in: .leading)

        var pathComponents = path.pathComponents
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
            currentStackView.insertView(textField, at: index + 1, in: .leading)
        }
    }
    
    func goToParent(_ tableView: NSTableView) {
        if let myTableView = tableView as? TableView {
            let parentUrl = myTableView.currentURL.deletingLastPathComponent()
            myTableView.currentURL = parentUrl
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
}

// MARK: - NSMenuDelegate
extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        menu.addItem(withTitle: "1st menu item", action: #selector(doNothing), keyEquivalent: "")
        menu.addItem(withTitle: "2nd menu item", action: #selector(doNothing), keyEquivalent: "")
    }
    
    @objc func doNothing() {
        let nameOfFile = urlRightClicked?.lastPathComponent ?? ""
        print("doing nothing...for \(nameOfFile)")
        urlRightClicked = nil
    }
}

// MARK: - TextFieldDelegate
extension ViewController: TextFieldDelegate {
    func pathRequested(_ textField: NSTextField, _ path: URL?, _ tableView: NSTableView?) {
        if let myNSTableView = tableView {
            if let myTableView = myNSTableView as? TableView {
                if let newUrl = path {
                    myTableView.currentURL = newUrl
                }
            }
        }
    }
}
