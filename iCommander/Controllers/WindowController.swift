//
//  WindowController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 01/11/2020.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet var helloButton: NSButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let mainWindow = window {
            mainWindow.delegate = self
        }
        
        if let myWindow = window, let screen = NSScreen.main {
            myWindow.setFrame(screen.visibleFrame, display: true)
        }        
    }
    
    @IBAction func handleTouchBarAction(_ sender: NSButton) {
        guard let viewController = window?.contentViewController as? ViewController else { return }
        
        switch sender.title {
        case "View":
            viewController.handleF3()
        case "Edit":
            viewController.handleF4()
        case "Copy":
            viewController.handleF5()
        case "Move":
            viewController.handleF6()
        case "New Folder":
            viewController.handleF7()
        case "Delete":
            viewController.handleF8()
        default:
            NSLog("Unknown touch bar action: %@", sender.title)
            break
        }
    }
}
