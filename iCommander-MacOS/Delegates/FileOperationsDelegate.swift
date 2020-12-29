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
            progressViewController.currentFileName.stringValue = fileName
        }
    }
    
    func copyStarted(_ uuid: String, _ totalBytes: Int) {
        instantiateProgressWindow()

        progressViewController?.overallProgressBar.minValue = Double(0)
        progressViewController?.overallProgressBar.maxValue = Double(totalBytes)
        progressViewController?.overallProgressBar.doubleValue = Double(0)
        
        progressWindowController?.showWindow(self)
    }
    
    func copyUpdateProgress(_ uuid: String, _ bytesCopied: Int) {
        progressViewController?.overallProgressBar.doubleValue = Double(bytesCopied)
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
