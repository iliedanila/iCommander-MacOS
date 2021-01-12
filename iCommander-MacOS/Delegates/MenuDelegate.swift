//
//  MenuDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 02/11/2020.
//

import Cocoa

// MARK: - NSMenuDelegate
extension ViewController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        
        guard let tableView =  tableViewForActivatedMenu else { return }
        guard let dataSource = tableToDataSource[tableView] else { return }
        
        let element = dataSource.tableElements[rowIndexForContexMenu]
        let name = element.name
        
        print("Right clicked on \(name)")
        
        if element.isPackage != nil && element.isPackage == true {
            menu.addItem(withTitle: "Show Contents", action: #selector(openDirectoryFromMenu), keyEquivalent: "")
        } else {
            menu.addItem(withTitle: "1st menu item", action: #selector(doNothing), keyEquivalent: "")
            menu.addItem(withTitle: "2nd menu item", action: #selector(doNothing), keyEquivalent: "")
        }
    }
    
    @objc func openDirectoryFromMenu() {
        guard let tableView =  tableViewForActivatedMenu else { return }
        guard let dataSource = tableToDataSource[tableView] else { return }
        let element = dataSource.tableElements[rowIndexForContexMenu]

        view.window?.makeFirstResponder(tableView)
        currentActiveTable = tableView
        dataSource.currentUrl = element.url
    }
    
    @objc func doNothing() {
    }
}
