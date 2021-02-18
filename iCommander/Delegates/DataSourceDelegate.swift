//
//  DataSourceDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 02/11/2020.
//

import Cocoa


// MARK: - DataSourceDelegate
extension ViewController: DataSourceDelegate {
    func handlePathChanged(_ dataSource: TableDataSource, _ newUrl: URL) {
        
        let tableView = dataSource.location == .Left ? leftTable : rightTable
        
        let tableViewData = dataSource.location == .Left ? leftTableData : rightTableData
        tableViewData?.currentUrlDBValue = newUrl
        
        refreshAddRemoveFavButton(newUrl)
        
        saveContext()
        
        tableView?.reloadData()
    }
    
    func refreshAddRemoveFavButton(_ url: URL) {
        if (favorites?.favURLs?.firstIndex(of: url)) != nil {
            addRemoveFavorite.title = "-"
            if #available(OSX 11.0, *) {
                addRemoveFavorite.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
            }
        } else {
            addRemoveFavorite.title = "+"
            if #available(OSX 11.0, *) {
                addRemoveFavorite.image = NSImage(systemSymbolName: "star", accessibilityDescription: nil)
            }
        }
    }
}
