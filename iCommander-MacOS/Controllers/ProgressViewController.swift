//
//  ProgressViewController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 29.11.2020.
//

import Cocoa

class ProgressViewController: NSViewController {

    @IBOutlet var currentFileName: NSTextField!
    @IBOutlet var fileProgressBar: NSProgressIndicator!
    @IBOutlet var overallProgressBar: NSProgressIndicator!
    @IBOutlet var fileProgressPercent: NSTextField!
    @IBOutlet var overallProgressPercent: NSTextField!
    @IBOutlet var playPauseButton: NSButton!
    @IBOutlet var cancelButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillDisappear() {
    }
    
    override func viewWillAppear() {
    }
}
