//
//  LocationHistory.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 07/11/2020.
//

import Foundation

protocol LocationHistoryDelegate {
    func goToDirectory(_ locationHistory: LocationHistory, _ url: URL, _ hasBack: Bool, _ hasForward: Bool)
    func updateBackForward(_ locationHistory: LocationHistory, _ hasBack: Bool, _ hasForward: Bool)
}

class LocationHistory {
    var delegate: LocationHistoryDelegate? = nil
    var locations: [URL] = []
    var currentPosition: Int = -1
    let locationOnScreen: LocationOnScreen
    
    init(_ aLocation: LocationOnScreen) {
        locationOnScreen = aLocation
    }
    
    func handleBackPressed() {
        if currentPosition > 0 {
            currentPosition = currentPosition - 1
            delegate?.goToDirectory(self, locations[currentPosition], currentPosition > 0, currentPosition < locations.count - 1)
        }
    }
    
    func handleForwardPressed() {
        if currentPosition < locations.count - 1 {
            currentPosition = currentPosition + 1
            delegate?.goToDirectory(self, locations[currentPosition], currentPosition > 0, currentPosition < locations.count - 1)
        }
    }
    
    func addDirectoryToHistory(_ url: URL) {
        locations.append(url)
        currentPosition = locations.count - 1
        delegate?.updateBackForward(self, currentPosition > 0, currentPosition < locations.count - 1)
    }
}
