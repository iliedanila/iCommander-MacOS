//
//  FileOperationsDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 17.11.2020.
//

import Cocoa

extension ViewController: FileOperationsDelegate {
    func startedFile(_ uuid: String, _ fileName: String) {
        if let progressViewController = self.progressViewController {
            progressViewController.fileProgressBar.doubleValue = 0
            progressViewController.currentFileName.stringValue = fileName
        }
    }
    
    func findStarted() {
        instantiateFindWindow()
        
        searchViewController?.progressBar.minValue = Double(0)
        searchViewController?.progressBar.maxValue = Double(1)
        searchViewController?.progressBar.doubleValue = Double(0)
        
        searchViewController?.searchTextField.stringValue = "Hello"
        
        searchWindowController?.showWindow(self)
    }
    
    func copyStarted(_ fileOperationsManager: FileOperations, _ uuid: String, _ totalBytes: UInt64) {
        instantiateProgressWindow()
        
        progressViewController?.fileOperationsManager = fileOperationsManager

        progressViewController?.overallProgressBar.minValue = Double(0)
        progressViewController?.overallProgressBar.maxValue = Double(1)
        progressViewController?.overallProgressBar.doubleValue = Double(0)
        
        progressViewController?.fileProgressBar.minValue = 0
        progressViewController?.fileProgressBar.maxValue = 1
        progressViewController?.fileProgressBar.doubleValue = 0
        
        if let window = NSApplication.shared.mainWindow {
            let width = (progressWindowController?.window?.frame.width)!
            let height = (progressWindowController?.window?.frame.height)!
            
            let mainWidth = window.frame.width
            let mainHeight = window.frame.height

            let x = (mainWidth - width) / 2
            let y = (mainHeight - height) / 2 + height
            
            progressWindowController?.window?.setFrameTopLeftPoint(NSPoint(x: x, y: y))
        }
        progressWindowController?.showWindow(self)
    }
    
    func copyUpdateProgress(_ uuid: String, _ fileProgress: Double, _ overallProgress: Double) {
        progressViewController?.fileProgressBar.doubleValue = fileProgress
        progressViewController?.overallProgressBar.doubleValue = overallProgress
        
        progressViewController?.fileProgressPercent.stringValue = String(format: "%.2f", 100 * fileProgress) + "%"
        progressViewController?.overallProgressPercent.stringValue = String(format: "%.2f", 100 * overallProgress) + "%"
    }
    
    
    func fileOperationCompleted(_ error: Error?) {
        progressWindowController?.window?.close()
        
        leftTableDataSource.checkPathIsStillValid()
        rightTableDataSource.checkPathIsStillValid()
                
        self.leftTable.reloadData()
        self.rightTable.reloadData()
    }
    
    func instantiateFindWindow() {
        if let _ = searchWindowController,
           let _ = searchViewController { return }
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "SearchWindowController")
        
        guard   let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? SearchWindowController,
                let progressViewController = windowController.contentViewController as? SearchViewController else { return }

        self.searchWindowController = windowController
        self.searchViewController = progressViewController
    }
    
    func instantiateProgressWindow() {
        if let _ = progressWindowController,
           let _ = progressViewController { return }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "ProgressWindowController")
        
        guard   let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? ProgressWindowController,
                let progressViewController = windowController.contentViewController as? ProgressViewController else { return }
        
        self.progressWindowController = windowController
        self.progressViewController = progressViewController
    }
}
