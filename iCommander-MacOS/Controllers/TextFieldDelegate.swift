//
//  TextFieldDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 02/11/2020.
//

import Cocoa

// MARK: - TextFieldDelegate
extension ViewController: TextFieldDelegate {
    func pathRequested(_ textField: NSTextField, _ path: URL?, _ tableView: NSTableView?) {
        
        if let nsTableView = tableView, let tableData = tableToDataSource[nsTableView], let locationHistory = tableToLocationHistory[nsTableView] {
            if let newUrl = path {
                tableData.currentUrl = newUrl
                locationHistory.addDirectoryToHistory(newUrl)
            }
        }
    }
}
