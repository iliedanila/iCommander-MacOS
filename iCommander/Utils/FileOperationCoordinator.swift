//
//  FileOperationCoordinator.swift
//  iCommander-MacOS
//
//  Coordinates file operations between UI and business logic
//

import Cocoa

/// Coordinates file operations and manages progress windows
class FileOperationCoordinator {
    
    weak var viewController: ViewController?
    
    private var progressWindowController: ProgressWindowController?
    private var progressViewController: ProgressViewController?
    private var fileOperations = FileOperations()
    
    init(viewController: ViewController) {
        self.viewController = viewController
        fileOperations.delegate = self
    }
    
    // MARK: - Public Methods
    
    func copyFiles(_ sources: [URL], to destination: URL) {
        fileOperations.copy(sources, destination)
    }
    
    func moveFiles(_ sources: [TableElement], to destination: URL) {
        fileOperations.move(sources, destination)
    }
    
    func renameFile(_ source: URL, in directory: URL, to newName: String) {
        fileOperations.rename(source, directory, newName)
    }
    
    func deleteFile(_ item: TableElement) {
        fileOperations.delete(item)
    }
    
    // MARK: - Progress Window Management
    
    private func instantiateProgressWindow() {
        guard progressWindowController == nil else { return }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("ProgressWindowController")
        
        guard let windowController = storyboard.instantiateController(withIdentifier: identifier) as? ProgressWindowController,
              let progressVC = windowController.contentViewController as? ProgressViewController else {
            NSLog("Failed to instantiate progress window")
            return
        }
        
        self.progressWindowController = windowController
        self.progressViewController = progressVC
    }
    
    private func showProgressWindow() {
        guard let windowController = progressWindowController,
              let mainWindow = NSApplication.shared.mainWindow else {
            return
        }
        
        if let progressWindow = windowController.window {
            let mainFrame = mainWindow.frame
            let progressSize = progressWindow.frame.size
            
            let x = mainFrame.midX - progressSize.width / 2
            let y = mainFrame.midY - progressSize.height / 2
            
            progressWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        windowController.showWindow(nil)
    }
    
    private func hideProgressWindow() {
        progressWindowController?.close()
    }
}

// MARK: - FileOperationsDelegate

extension FileOperationCoordinator: FileOperationsDelegate {
    
    func copyStarted(_ fileOperationsManager: FileOperations, _ uuid: String, _ totalBytes: UInt64) {
        instantiateProgressWindow()
        
        progressViewController?.fileOperationsManager = fileOperationsManager
        progressViewController?.overallProgressBar.minValue = 0
        progressViewController?.overallProgressBar.maxValue = 1
        progressViewController?.overallProgressBar.doubleValue = 0
        progressViewController?.fileProgressBar.minValue = 0
        progressViewController?.fileProgressBar.maxValue = 1
        progressViewController?.fileProgressBar.doubleValue = 0
        
        showProgressWindow()
    }
    
    func startedFile(_ uuid: String, _ fileName: String) {
        progressViewController?.fileProgressBar.doubleValue = 0
        progressViewController?.currentFileName.stringValue = fileName
    }
    
    func copyUpdateProgress(_ uuid: String, _ fileProgress: Double, _ overallProgress: Double) {
        progressViewController?.fileProgressBar.doubleValue = fileProgress
        progressViewController?.overallProgressBar.doubleValue = overallProgress
        progressViewController?.fileProgressPercent.stringValue = String(format: "%.1f%%", fileProgress * 100)
        progressViewController?.overallProgressPercent.stringValue = String(format: "%.1f%%", overallProgress * 100)
    }
    
    func fileOperationCompleted(_ error: Error?) {
        hideProgressWindow()
        
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.showErrorAlert(error)
            }
        }
        
        // Refresh both panels
        viewController?.leftTable.reloadData()
        viewController?.rightTable.reloadData()
    }
    
    private func showErrorAlert(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = "File Operation Error"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
