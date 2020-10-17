//
//  TextField.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 17/10/2020.
//

import Cocoa

protocol TextFieldDelegate {
    func pathRequested(_ textField: NSTextField, _ path: URL?, _ tableView: NSTableView?)
}

class TextField: NSTextField {
    
    var path: URL? = nil
    var previousColor: NSColor? = nil
    var tableViewAssociated: NSTableView? = nil
    var textFieldDelegate: TextFieldDelegate? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    override func mouseEntered(with event: NSEvent) {
        previousColor = textColor
        textColor = .systemBlue
    }
    
    override func mouseExited(with event: NSEvent) {
        textColor = previousColor
    }
    
    override func mouseDown(with event: NSEvent) {
        textFieldDelegate?.pathRequested(self, path, tableViewAssociated)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        for trackingArea in self.trackingAreas {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways]
        let trackingArea = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}
