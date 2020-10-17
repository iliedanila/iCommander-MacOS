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
        }
        
        leftTable.rowSizeStyle = .medium
        rightTable.rowSizeStyle = .medium
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

// MARK: - NSTableViewDelegate

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let identifier = NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier.rawValue)!)
        
        if let cell = tableView.makeView(withIdentifier: identifier, owner: nil) as? NSTableCellView {
            
            if let myTableView = tableView as? TableView {
                let url = myTableView.currentFolderContents[row]
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                let name = url.lastPathComponent
                cell.textField?.stringValue = name
                cell.imageView?.image = icon
                
                return cell
            }
        }
        return nil
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

        var pathComponents = path.pathComponents
        for index in 1..<pathComponents.count {
            pathComponents[index] = pathComponents[index] + "/"
        }
        
        var currentPath = ""
        for index in 0..<pathComponents.count {
            currentPath = currentPath + pathComponents[index]
            let currentUrl = URL(fileURLWithPath: currentPath)
            
            let textField = TextField()
            textField.textFieldDelegate = self
            textField.path = currentUrl
            textField.tableViewAssociated = tableView
            
            textField.stringValue = pathComponents[index]
            textField.isEditable = false
            textField.isSelectable = false
            textField.isBezeled = false
            textField.isBordered = false
            textField.backgroundColor = .none
            textField.drawsBackground = false
            textField.isEnabled = true
            currentStackView.insertView(textField, at: index, in: .leading)
        }
    }
    
    func goToParent(_ tableView: NSTableView) {
        if let myTableView = tableView as? TableView {
            let parentUrl = myTableView.currentURL.deletingLastPathComponent()
            myTableView.currentURL = parentUrl
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
