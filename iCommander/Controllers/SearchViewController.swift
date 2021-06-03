//
//  SearchViewController.swift
//  iCommander
//
//  Created by Ilie Danila on 27.02.2021.
//

import Cocoa

class SearchViewController: NSViewController {

    @IBOutlet var searchTextField: NSTextField!
    @IBOutlet var progressBar: NSProgressIndicator!
    
    var fileOperationsManager: FileOperations? = nil
    var currentFolder: URL? = nil
  
    @IBAction func cancelPressed(_ sender: NSButton) {
        fileOperationsManager?.delegate?.findCompleted()
    }

    @IBAction func textUpdated(_ sender: NSTextField) {
        print("Search text updated: \(sender.stringValue)")
        fileOperationsManager?.startSearch(sender.stringValue, currentFolder!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
