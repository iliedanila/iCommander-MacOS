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
  
    @IBAction func cancelPressed(_ sender: NSButton) {
        fileOperationsManager?.delegate?.findCompleted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
