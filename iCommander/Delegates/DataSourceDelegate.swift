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
        let pathLabel = dataSource.location == .Left ? leftPath : rightPath
        
        pathLabel?.stringValue = newUrl.path
        
        let tableViewData = dataSource.location == .Left ? leftTableData : rightTableData
        tableViewData?.currentUrlDBValue = newUrl
        
        refreshAddRemoveFavButton(newUrl)
        
        saveContext()
        
        tableView?.reloadData()
    }
}
