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
    
    func copyStarted(_ fileOperationsManager: FileOperations, _ uuid: String, _ totalBytes: UInt64) {
        instantiateProgressWindow()
        
        progressViewController?.fileOperationsManager = fileOperationsManager

        progressViewController?.overallProgressBar.minValue = Double(0)
        progressViewController?.overallProgressBar.maxValue = Double(1)
        progressViewController?.overallProgressBar.doubleValue = Double(0)
        
        progressViewController?.fileProgressBar.minValue = 0
        progressViewController?.fileProgressBar.maxValue = 1
        progressViewController?.fileProgressBar.doubleValue = 0
        
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
                
        self.leftTable.reloadData()
        self.rightTable.reloadData()
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
