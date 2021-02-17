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
        
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
        
        tableView?.reloadData()
    }
}
