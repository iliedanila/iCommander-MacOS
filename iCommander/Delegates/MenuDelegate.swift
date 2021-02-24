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
        
        if rowIndexForContexMenu != -1 {
            let element = dataSource.tableElements[rowIndexForContexMenu]
            
            if element.isPackage != nil && element.isPackage == true {
                menu.addItem(withTitle: "Show Contents", action: #selector(openDirectoryFromMenu), keyEquivalent: "")
            }
            
            // Copy
            menu.addItem(withTitle: "Copy", action: nil, keyEquivalent: "")
        }
        
        menu.addItem(withTitle: "Open in Finder", action: #selector(openInFinder), keyEquivalent: "")
        
        menu.addItem(withTitle: "Open Terminal", action: #selector(openTerminal), keyEquivalent: "")
        
        // Paste
        menu.addItem(withTitle: "Paste", action: nil, keyEquivalent: "")
        
        // New... -> Text Document
        let newMenuItem = NSMenuItem(title: "New...", action: nil, keyEquivalent: "")
        menu.addItem(newMenuItem)
        let submenu = NSMenu(title: "New...")
        let newTextFile = NSMenuItem(title: "Text Document", action: #selector(doNothing), keyEquivalent: "")
        submenu.addItem(newTextFile)
        menu.setSubmenu(submenu, for: newMenuItem)
        
        // Rename
        if rowIndexForContexMenu != -1 {
            menu.addItem(withTitle: "Rename", action: #selector(doNothing), keyEquivalent: "")
        }
    }
    
    @objc func openTerminal() {
        guard let tableView =  tableViewForActivatedMenu else { return }
        guard let dataSource = tableToDataSource[tableView] else { return }
        let currentURL = dataSource.currentURL
        
        guard let terminalURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else { return }
        let conf = NSWorkspace.OpenConfiguration()
        conf.activates = true
        conf.arguments = [currentURL.path]
        
        NSWorkspace.shared.openApplication(at: terminalURL, configuration: conf, completionHandler: nil)
    }
    
    @objc func openInFinder() {
        guard let tableView =  tableViewForActivatedMenu else { return }
        guard let dataSource = tableToDataSource[tableView] else { return }
        
        if rowIndexForContexMenu == -1 {
            NSWorkspace.shared.open(dataSource.currentURL)
        } else {
            let element = dataSource.tableElements[rowIndexForContexMenu]
            NSWorkspace.shared.open(element.url)
        }
    }
    
    @objc func openDirectoryFromMenu() {
        guard let tableView =  tableViewForActivatedMenu else { return }
        guard let dataSource = tableToDataSource[tableView] else { return }
        let element = dataSource.tableElements[rowIndexForContexMenu]

        view.window?.makeFirstResponder(tableView)
        currentActiveTable = tableView
        dataSource.currentURL = element.url
    }
    
    @objc func doNothing() {
    }
}
