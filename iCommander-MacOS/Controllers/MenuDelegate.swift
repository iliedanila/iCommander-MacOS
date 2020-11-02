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

        menu.addItem(withTitle: "1st menu item", action: #selector(doNothing), keyEquivalent: "")
        menu.addItem(withTitle: "2nd menu item", action: #selector(doNothing), keyEquivalent: "")
    }
    
    @objc func doNothing() {
    }
}
