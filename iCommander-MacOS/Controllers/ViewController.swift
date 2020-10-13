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
    
    var tableURLDict: [NSTableView: URL] = [:]
    var tableContentDict: [NSTableView: [URL]] = [:]
    
    @IBAction func leftTableDoubleClick(_ sender: NSTableView) {
        print("Left table: \(sender.clickedRow)")
        
        if sender.clickedRow == -1 {
            return
        }
        
        let itemURL = tableContentDict[leftTable]![sender.clickedRow]
        tableURLDict[leftTable] = itemURL

        leftTable.reloadData()
        leftTable.scrollRowToVisible(0)
    }
    
    @IBAction func rightTableDoubleClick(_ sender: NSTableView) {
        print("Right table: \(sender.clickedRow)")
        
        if sender.clickedRow == -1 {
            return
        }
        
        let itemURL = tableContentDict[rightTable]![sender.clickedRow]
        tableURLDict[rightTable] = itemURL
        
        rightTable.reloadData()
        rightTable.scrollRowToVisible(0)
    }
    
    @IBAction func leftUpClicked(_ sender: NSButton) {
        let currentUrl = tableURLDict[leftTable]
        let parentUrl = currentUrl?.deletingLastPathComponent()
        
        tableURLDict[leftTable] = parentUrl
        leftTable.reloadData()
        leftTable.scrollRowToVisible(0)
    }
    
    @IBAction func rightUpClicked(_ sender: NSButton) {
        let currentUrl = tableURLDict[rightTable]
        let parentUrl = currentUrl?.deletingLastPathComponent()
        
        tableURLDict[rightTable] = parentUrl
        rightTable.reloadData()
        rightTable.scrollRowToVisible(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableURLDict[leftTable] = FileManager.default.homeDirectoryForCurrentUser
        tableURLDict[rightTable] = FileManager.default.homeDirectoryForCurrentUser
        tableContentDict[leftTable] = []
        tableContentDict[rightTable] = []

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
            
            let url = tableContentDict[tableView]![row]
            let icon = NSWorkspace.shared.icon(forFile: url.path)
            let name = url.lastPathComponent
                        
            cell.textField?.stringValue = name
            cell.imageView?.image = icon

            return cell
        }
        
        return nil
    }
}

// MARK: - NSTableViewDataSource

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        do {
            let fileManager = FileManager.default
            let currentPathUrl = tableURLDict[tableView]!
            
            let fileURLs = try fileManager.contentsOfDirectory(at: currentPathUrl, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
            
            tableContentDict[tableView] = fileURLs
                        
            return fileURLs.count
        } catch {
            print("error")
            return 0
        }
    }
}
