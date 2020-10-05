//
//  ViewController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 29/09/2020.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var leftTable: NSTableView!
    @IBOutlet var rightTable: NSTableView!
    
    var tableDict: [NSTableView: Int] = [:]
    
    @IBAction func leftTableDoubleClick(_ sender: NSTableView) {
        print("Left table: \(sender.clickedRow)")
    }
    
    @IBAction func rightTableDoubleClick(_ sender: NSTableView) {
        print("Right table: \(sender.clickedRow)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableDict[leftTable] = 1
        tableDict[rightTable] = 2
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

extension ViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let cellText = "Table \(tableDict[tableView]!) Row \(row) Column 0"
        let identifier = NSUserInterfaceItemIdentifier(rawValue: (tableColumn?.identifier.rawValue)!)
        
        if let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            
            cell.textField?.stringValue = cellText
            return cell
        }
        
        return nil
    }
}

extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 10
    }
}
