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
        if let stackView = dataSource.location == .Left ? leftPathStackView : rightPathStackView {
            let views = stackView.arrangedSubviews
            for view in views {
                stackView.removeView(view)
            }
            
            let firstTextField = NSTextField()
            setupTextField(firstTextField, Constants.CurrentPath)
            stackView.insertView(firstTextField, at: 0, in: .leading)

            var pathComponents = newUrl.pathComponents
            for index in 1..<pathComponents.count {
                pathComponents[index] = pathComponents[index] + "/"
            }
            
            var currentPath = ""
            for index in 0..<pathComponents.count {
                currentPath = currentPath + pathComponents[index]
                let currentUrl = URL(fileURLWithPath: currentPath)
                
                let textField = TextField()
                setupTextField(textField, pathComponents[index])
                textField.textFieldDelegate = self
                textField.path = currentUrl
                textField.tableViewAssociated = tableView
                stackView.insertView(textField, at: index + 1, in: .leading)
            }
        }
        
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
