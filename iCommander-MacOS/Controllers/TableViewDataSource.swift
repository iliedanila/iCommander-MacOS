//
//  TableViewDataSource.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 02/11/2020.
//

import Cocoa

// MARK: - NSTableViewDataSource
extension ViewController: NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if let dataSource = tableToDataSource[tableView] {
            return dataSource.tableElements.count
        }
        return 0
    }
}
