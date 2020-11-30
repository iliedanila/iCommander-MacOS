//
//  ProgressViewController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 29.11.2020.
//

import Cocoa

class ProgressViewController: NSViewController {

    @IBOutlet var currentFileName: NSTextField!
    @IBOutlet var progressBar: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillDisappear() {
    }
    
    override func viewWillAppear() {
    }
}
