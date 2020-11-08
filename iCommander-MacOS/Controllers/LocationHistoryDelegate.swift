//
//  LocationHistoryDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 07/11/2020.
//

import Cocoa

// MARK: - LocationHistoryDelegate
extension ViewController: LocationHistoryDelegate {
    func goToDirectory(_ locationHistory: LocationHistory, _ url: URL, _ hasBack: Bool, _ hasForward: Bool) {
        let tableDataSource = locationHistory.locationOnScreen == .Left ? leftTableDataSource : rightTableDataSource
        tableDataSource.currentUrl = url
    }
}
