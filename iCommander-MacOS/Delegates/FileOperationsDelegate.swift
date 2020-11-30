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
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "ProgressWindowController")
        
        guard   let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? ProgressWindowController,
                let progressViewController = windowController.contentViewController as? ProgressViewController else { return }
        
        self.progressViewController = progressViewController
        progressViewController.progressBar.maxValue = Double(totalBytes)
        progressViewController.progressBar.doubleValue = Double(0)
        
//        NSApplication.shared.runModal(for: progressWindow)
        windowController.showWindow(self)
        
    }
    
    func copyUpdateProgress(_ uuid: String, _ bytesCopied: Int) {
        if let progressViewController = self.progressViewController {
            progressViewController.progressBar.doubleValue = Double(bytesCopied)
        }
    }
    
    
    func fileOperationCompleted(_ error: Error?) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let sceneIdentifier = NSStoryboard.SceneIdentifier(stringLiteral: "ProgressWindowController")
        
        if let windowController = storyboard.instantiateController(withIdentifier: sceneIdentifier) as? ProgressWindowController {
            windowController.window?.performClose(self)
        }
                
        self.leftTable.reloadData()
        self.rightTable.reloadData()
    }
}
