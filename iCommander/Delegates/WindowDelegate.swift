//
//  WindowDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 16.12.2020.
//

import Cocoa

extension WindowController: NSWindowDelegate {
    func windowDidResize(_ notification: Notification) {
        if let window = notification.object as? NSWindow,
           let viewController = window.contentViewController as? ViewController {
            viewController.handleMaximize()
        }
    }
}
