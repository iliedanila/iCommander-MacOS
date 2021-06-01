//
//  ProgressViewController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 29.11.2020.
//

import Cocoa

class ProgressViewController: NSViewController {

    @IBOutlet var folderName: NSTextField!
    @IBOutlet var currentFileName: NSTextField!
    @IBOutlet var fileProgressBar: NSProgressIndicator!
    @IBOutlet var overallProgressBar: NSProgressIndicator!
    @IBOutlet var fileProgressPercent: NSTextField!
    @IBOutlet var overallProgressPercent: NSTextField!
    @IBOutlet var playPauseButton: NSButton!
    @IBOutlet var cancelButton: NSButton!
    
    var fileOperationsManager: FileOperations? = nil
    
    @IBAction func playPauseButtonPressed(_ sender: NSButton) {
        switch sender.title {
        case "Pause":
            sender.title = "Continue"
            
            DispatchQueue.global(qos: .background).async {
                self.fileOperationsManager?.state = .Paused
            }
            
            break
        case "Continue":
            sender.title = "Pause"
            
            DispatchQueue.global(qos: .background).async {
                self.fileOperationsManager?.state = .Running
            }
            
            break
        default:
            break
        }
    }
    
    @IBAction func cancel(_ sender: NSButton) {
        playPauseButton.title = "Pause"
        DispatchQueue.global(qos: .background).async {
            self.fileOperationsManager?.state = .Stopped
        }
    }
    
    override func viewDidLoad() {
        playPauseButton.title = "Pause"
        super.viewDidLoad()
    }
    
    override func viewWillDisappear() {
    }
    
    override func viewWillAppear() {
    }
}
