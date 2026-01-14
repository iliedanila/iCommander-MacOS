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

        // Update path label based on search mode
        if dataSource.isInSearchMode, let searchRoot = dataSource.searchRootURL {
            pathLabel?.stringValue = "Search: \(dataSource.searchQuery) in \(searchRoot.path)"
        } else {
            pathLabel?.stringValue = newUrl.path
        }

        let tableViewData = dataSource.location == .Left ? leftTableData : rightTableData
        tableViewData?.currentUrlDBValue = newUrl

        refreshAddRemoveFavButton(newUrl)

        saveContext()

        tableView?.reloadData()
    }

    func handleAccessDenied(_ dataSource: TableDataSource, _ url: URL) {
        let initialURL = url.hasDirectoryPath ? url : url.deletingLastPathComponent()
        let message = "iCommander needs permission to access \"\(url.path)\". Select a folder to grant access."

        guard let selectedURL = SandboxHelper.shared.requestFolderAccess(message: message, initialURL: initialURL) else {
            if let fallback = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                dataSource.currentURL = fallback
            }
            return
        }

        if let bookmark = SandboxHelper.shared.createBookmark(for: selectedURL) {
            PreferencesManager.shared.addSandboxBookmark(bookmark)
        }

        addSandboxAccess(for: selectedURL)
        dataSource.currentURL = selectedURL
    }
}
