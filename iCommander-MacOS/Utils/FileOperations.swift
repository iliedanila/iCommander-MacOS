//
//  FileOperations.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 16.11.2020.
//

import Foundation

typealias SourceDestinationPair = (source: URL, destination: URL)

protocol FileOperationsDelegate {
    func fileOperationCompleted(_ error: Error?)
}

class FileOperations {
    
    var delegate: FileOperationsDelegate?
    
    func copy(_ sourceItem: TableElement, _ destinationDirectory: URL) {
        let queue = prepareQueue(sourceItem, destinationDirectory)
        processQueue(queue)
    }
    
    func move(_ sourceItem: TableElement, _ destinationDirectory: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                try FileManager.default.moveItem(at: sourceItem.url, to: destinationDirectory.appendingPathComponent(sourceItem.name))
                self.delegate?.fileOperationCompleted(nil)
            } catch {
                print("Error while moving item: \(error)")
            }
        }
    }
    
    func delete(_ item: TableElement) {
        do {
            try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
            self.delegate?.fileOperationCompleted(nil)
        } catch {
            print("Error while deleting element: \(error)")
        }
    }
    
    func prepareQueue(_ sourceItem: TableElement, _ destinationDirectory: URL) -> [SourceDestinationPair]{
        var queue: [SourceDestinationPair] = []
        var urlList: [SourceDestinationPair] = []
        urlList.append((sourceItem.url, destinationDirectory))
        var index: Int = 0
        
        while index < urlList.count {
            let currentUrl = urlList[index].source
            let destinationFolderUrl = urlList[index].destination
            
            if currentUrl.hasDirectoryPath {
                // Create proper directory at destination
                let destinationUrl = destinationFolderUrl.appendingPathComponent(currentUrl.lastPathComponent)
                do {
                    try FileManager.default.createDirectory(at: destinationUrl, withIntermediateDirectories: true, attributes: [:])
                } catch {
                    print("Error while creating directory: \(error)")
                }
                
                // Add all contents to urlList
                do {
                    let directoryContents = try FileManager.default.contentsOfDirectory(at: currentUrl, includingPropertiesForKeys: [], options: [.skipsSubdirectoryDescendants])
                    for url in directoryContents {
                        urlList.append((url, destinationUrl))
                    }
                } catch {
                    print("Error while getting contents of directory: \(error)")
                }
            } else {
                queue.append((currentUrl, destinationFolderUrl.appendingPathComponent(currentUrl.lastPathComponent)))
            }
            
            index += 1
        }
        
        return queue
    }
    
    func processQueue(_ queue: [SourceDestinationPair]) {
        DispatchQueue.global(qos: .background).async {
            for pair in queue {
                guard let isAlias = self.getIsAlias(pair.source) else { return }
                
                if isAlias {
                    do {
                        try FileManager.default.copyItem(at: pair.source, to: pair.destination)
                    } catch {
                        print("Error while copying file: \(pair.source.lastPathComponent) - Error: \(error)")
                    }
                } else {
                    guard let inputStream = InputStream(url: pair.source) else { return }
                    guard let outputStream = OutputStream(url: pair.destination, append: false) else { return }
                    
                    inputStream.open()
                    outputStream.open()
                    
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 1025)
                    
                    while inputStream.hasBytesAvailable {
                        let bytesCount = inputStream.read(buffer, maxLength: 1024)
                        outputStream.write(buffer, maxLength: bytesCount)
                    }
                }
            }
            self.delegate?.fileOperationCompleted(nil)
        }
    }
    
    func getIsAlias(_ forURL: URL) -> Bool? {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.isAliasFileKey])
            return  resourceValues.isAliasFile
        } catch {
            print("Error while getting resource value isAliasFile: \(error)")
            return nil
        }
    }
}
