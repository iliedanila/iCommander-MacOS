//
//  DriveButton.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 28.12.2020.
//

import Cocoa

class DriveButton: NSButton {
    
    var drivePath: String?
    var locationOnScreen: LocationOnScreen?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
}
