//
//  FileOperationsDelegate.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 17.11.2020.
//

import Foundation

extension ViewController: FileOperationsDelegate {
    
    func fileOperationCompleted(_ error: Error?) {
        DispatchQueue.main.async {
            self.leftTable.reloadData()
            self.rightTable.reloadData()
        }
    }
}
