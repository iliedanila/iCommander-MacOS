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
    }
    
    @IBAction func sayHello(_ sender: NSButton) {
        let hello = NSAlert()
        hello.messageText = "Hello there! :)"
        hello.alertStyle = .informational
        hello.addButton(withTitle: "OK")
        hello.runModal()
    }
}
