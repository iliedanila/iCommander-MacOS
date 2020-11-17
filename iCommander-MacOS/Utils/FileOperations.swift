//
//  FileOperations.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 16.11.2020.
//

import Foundation

class FileOperations {
    
    static func copyFile(_ sourceItem: TableElement, _ destinationDirectory: URL) {
        DispatchQueue.global(qos: .background).async {
            let destinationURL = destinationDirectory.appendingPathComponent(sourceItem.name)
            
            if let inputStream = InputStream(url: sourceItem.url),
               let outputStream = OutputStream(url: destinationURL, append: false) {
                
                inputStream.open()
                outputStream.open()
                
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1025)
                
                while inputStream.hasBytesAvailable {
                    inputStream.read(buffer, maxLength: 1024)
                    outputStream.write(buffer, maxLength: 1024)
                }
            }
        }
    }
}
