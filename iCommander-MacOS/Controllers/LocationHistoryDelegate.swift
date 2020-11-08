//
//  LocationHistoryDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 07/11/2020.
//

import Cocoa

// MARK: - LocationHistoryDelegate
extension ViewController: LocationHistoryDelegate {
    func updateBackForward(_ locationHistory: LocationHistory, _ hasBack: Bool, _ hasForward: Bool) {
        let backButton = locationHistory.locationOnScreen == .Left ? leftBackButton : rightBackButton
        backButton?.isEnabled = hasBack
        
        let forwardButton = locationHistory.locationOnScreen == .Left ? leftForwardButton : rightForwardButton
        forwardButton?.isEnabled = hasForward
    }
    
    func goToDirectory(_ locationHistory: LocationHistory, _ url: URL, _ hasBack: Bool, _ hasForward: Bool) {
        let tableDataSource = locationHistory.locationOnScreen == .Left ? leftTableDataSource : rightTableDataSource
        tableDataSource.currentUrl = url
        
        updateBackForward(locationHistory, hasBack, hasForward)
    }
}
