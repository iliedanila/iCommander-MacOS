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
    @IBOutlet var leftPathTextField: NSTextField!
    @IBOutlet var rightPathTextField: NSTextField!
    
    var tableToPath: [NSTableView : NSTextField] = [:]
    
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
        
        tableToPath[leftTable] = leftPathTextField
        tableToPath[rightTable] = rightPathTextField
        
        if let leftTableView = leftTable as? TableView, let rightTableView = rightTable as? TableView {
            leftTableView.currentURL = FileManager.default.homeDirectoryForCurrentUser
            rightTableView.currentURL = FileManager.default.homeDirectoryForCurrentUser
            leftTableView.tableViewDelegate = self
            rightTableView.tableViewDelegate = self
            leftPathTextField.stringValue = Constants.CurrentPath + leftTableView.currentURL.path
            rightPathTextField.stringValue = Constants.CurrentPath + rightTableView.currentURL.path
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
    func currentPathChanged(_ tableView: NSTableView, _ path: String) {
        var pathText = Constants.CurrentPath
        pathText = pathText + path
        tableToPath[tableView]?.stringValue = pathText
    }
    
    func goToParent(_ tableView: NSTableView) {
        if let myTableView = tableView as? TableView {
            let parentUrl = myTableView.currentURL.deletingLastPathComponent()
            myTableView.currentURL = parentUrl
        }
    }
}
