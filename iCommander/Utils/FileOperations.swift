//
//  FileOperations.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 16.11.2020.
//

import Cocoa

typealias SourceDestination = (source: URL, destination: URL)
typealias SourceDestinationSize = (source: URL, destination: URL, size: UInt64)

let chunkSize: Int = 1024 * 5

protocol FileOperationsDelegate {
    func copyStarted(_ fileOperationsManager: FileOperations, _ uuid: String, _ totalBytes: UInt64)
    func startedFile(_ uuid: String, _ fileName: String)
    func copyUpdateProgress(_ uuid: String, _ fileProgress: Double, _ overallProgress: Double)
    func fileOperationCompleted(_ error: Error?)
}

class FileOperations {
    
    enum State {
        case Running
        case Paused
        case Stopped
        case Finished
    }
    
    var delegate: FileOperationsDelegate?
    var totalBytesCopied: Int = 0
    var totalBytesToCopy: UInt64 = 0
    var uuid: String = ""
    var state: State = .Running
    
    func copy(_ sourceItems: [URL], _ destinationDirectory: URL) {
        DispatchQueue.global(qos: .background).async {
            
            self.uuid = UUID().uuidString
            
            var queue = self.prepareQueue(sourceItems, destinationDirectory, totalBytes: &self.totalBytesToCopy)
            
            DispatchQueue.main.async {
                self.delegate?.copyStarted(self, self.uuid, self.totalBytesToCopy)
            }
            
            self.processNextFileInQueue(&queue)
        }
    }
    
    func rename(_ sourceItem: URL, _ currentDirectory: URL, _ newName: String) {
        DispatchQueue.global(qos: .background).async {
            do {
                try FileManager.default.moveItem(at: sourceItem, to: currentDirectory.appendingPathComponent(newName))
                
                DispatchQueue.main.async {
                    self.delegate?.fileOperationCompleted(nil)
                }
            } catch {
                print("Error while renaming item: \(error)")
            }
        }
    }
    
    func move(_ sourceItems: [TableElement], _ destinationDirectory: URL) {
        DispatchQueue.global(qos: .background).async {
            do {
                for sourceItem in sourceItems {
                    try FileManager.default.moveItem(at: sourceItem.url, to: destinationDirectory.appendingPathComponent(sourceItem.name))
                }
                
                DispatchQueue.main.async {
                    self.delegate?.fileOperationCompleted(nil)
                }
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
    
    func prepareQueue(_ sourceItems: [URL], _ destinationDirectory: URL, totalBytes: inout UInt64) -> [SourceDestinationSize] {
        var queue: [SourceDestinationSize] = []
        var urlList: [SourceDestination] = []
        let fileManager = FileManager.default
        
        for sourceItem in sourceItems {
            urlList.append((sourceItem, destinationDirectory))
        }
        var index: Int = 0
        
        while index < urlList.count {
            let currentUrl = urlList[index].source
            let destinationFolderUrl = urlList[index].destination
            
            if currentUrl.hasDirectoryPath {
                // Create proper directory at destination
                let destinationUrl = destinationFolderUrl.appendingPathComponent(currentUrl.lastPathComponent)
                var continueCopy = true
                
                if fileManager.fileExists(atPath: destinationUrl.path) {
                    continueCopy = promptOverwrite("Overwrite \(currentUrl.lastPathComponent)?", "A folder with the same name exists at the destination.")
                    print("Response: \(continueCopy)")
                }
                
                guard continueCopy == true else {
                    return []
                }
                
                do {
                    try fileManager.createDirectory(at: destinationUrl, withIntermediateDirectories: true, attributes: [:])
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
                let fileSize = getFileSize(currentUrl)
                totalBytes += fileSize
                let destinationURL = destinationFolderUrl.appendingPathComponent(currentUrl.lastPathComponent)
                queue.append((currentUrl, destinationURL, fileSize))
            }
            
            index += 1
        }
        
        return queue
    }
    
    func processNextFileInQueue(_ queue: inout [SourceDestinationSize]) {
        if state == .Stopped || state == .Finished{
            DispatchQueue.main.async {
                self.delegate?.fileOperationCompleted(nil)
            }
            state = .Running
            return
        } else if state == .Paused {
            Thread.sleep(forTimeInterval: 0.1) //seconds
            DispatchQueue.global(qos: .background).async { [queue] in
                var mutableQueue = queue
                self.processNextFileInQueue(&mutableQueue)
            }
            return
        } else { //Running
            if queue.isEmpty {
                state = .Finished
                DispatchQueue.main.async {
                    self.delegate?.fileOperationCompleted(nil)
                }
                
                DispatchQueue.global(qos: .background).async { [queue] in
                    var mutableQueue = queue
                    self.processNextFileInQueue(&mutableQueue)
                }
                return
            }
            
            let tuple = queue.removeFirst()
            let sourceURL = tuple.source
            let destinationURL = tuple.destination
            
            let fileManager = FileManager.default
            
            var continueCopy = true
            if fileManager.fileExists(atPath: destinationURL.path) {
                continueCopy = promptOverwrite("Overwrite \(sourceURL.lastPathComponent)?", "A file with the same name exists at the destination.")
                print("Response: \(continueCopy)")
            }
            
            guard continueCopy == true else {
                state = .Stopped
                DispatchQueue.global(qos: .background).async { [queue] in
                    var mutableQueue = queue
                    self.processNextFileInQueue(&mutableQueue)
                }
                return
            }
            
            let fileSize = tuple.size
            
            DispatchQueue.main.async {
                self.delegate?.startedFile(self.uuid, sourceURL.lastPathComponent)
            }
            
            guard let isAlias = self.getIsAlias(tuple.source) else { return }
            
            if isAlias || self.isOnTheSameVolume(tuple.source, tuple.destination) {
                do {
                    try FileManager.default.copyItem(at: tuple.source, to: tuple.destination)
                    DispatchQueue.global(qos: .background).async { [queue] in
                        var mutableQueue = queue
                        self.processNextFileInQueue(&mutableQueue)
                    }
                } catch {
                    print("Error while copying file: \(tuple.source.lastPathComponent) - Error: \(error)")
                }
            } else {
                do {
                    let fileManager = FileManager.default
                    let attributes = try fileManager.attributesOfItem(atPath: sourceURL.path)
                    fileManager.createFile(atPath: destinationURL.path, contents: nil, attributes: attributes)
                    
                    DispatchQueue.global(qos: .background).async { [queue] in
                        self.processNextChuckInFile(sourceURL.path, destinationURL.path, 0, fileSize, queue)
                    }
                } catch {
                    print(error)
                }
            }
        }
    }
    
    func processNextChuckInFile(
        _ sourcePath: String,
        _ destinationPath: String,
        _ bytesCopiedInFile: UInt64,
        _ fileSize: UInt64,
        _ queue: [SourceDestinationSize]) {
            
            if state == .Stopped {
                DispatchQueue.main.async {
                    self.delegate?.fileOperationCompleted(nil)
                }
                state = .Running
                return
            } else if state == .Paused {
                Thread.sleep(forTimeInterval: 0.1) //seconds
                DispatchQueue.global(qos: .background).async {
                    self.processNextChuckInFile(sourcePath, destinationPath, bytesCopiedInFile, fileSize, queue)
                }
            } else if state == .Running {
                if let inFile = FileHandle(forReadingAtPath: sourcePath),
                   let outFile = FileHandle(forWritingAtPath: destinationPath) {
                    do {
                        try inFile.seek(toOffset: bytesCopiedInFile)
                        
                        if #available(OSX 10.15.4, *) {
                            try outFile.seekToEnd()
                        }
                        
                        let data = inFile.readData(ofLength: chunkSize)
                        outFile.write(data)
                        
                        let bytesCopiedCount = bytesCopiedInFile + UInt64(data.count)
                        totalBytesCopied += data.count
                        
                        DispatchQueue.main.async {
                            let fileProgress = Double(bytesCopiedCount) / Double(fileSize)
                            let overallProgress = Double(self.totalBytesCopied) / Double(self.totalBytesToCopy)
                            self.delegate?.copyUpdateProgress(self.uuid, fileProgress, overallProgress)
                        }
                        
                        if bytesCopiedCount < fileSize {
                            DispatchQueue.global(qos: .background).async {
                                self.processNextChuckInFile(sourcePath, destinationPath, bytesCopiedCount, fileSize, queue)
                            }
                        } else {
                            DispatchQueue.global(qos: .background).async { [queue] in
                                var mutableQueue = queue
                                self.processNextFileInQueue(&mutableQueue)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
    
    func promptOverwrite(_ message: String, _ info: String) -> Bool {
        return DispatchQueue.main.sync {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = message
            alert.informativeText = info
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            
            return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
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
    
    func getFileSize(_ forURL: URL) -> UInt64 {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.fileSizeKey])
            return UInt64(resourceValues.fileSize!)
        } catch {
            print("Error while getting file size for: \(forURL.lastPathComponent)")
        }
        return 0
    }
    
    func isOnTheSameVolume(_ sourceURL: URL, _ destinationURL: URL) -> Bool {
        do {
            let sourceVolumeID = try sourceURL.resourceValues(forKeys: [.volumeIdentifierKey])
            let destinationVolumeID = try destinationURL.deletingLastPathComponent().resourceValues(forKeys: [.volumeIdentifierKey])
            
            return sourceVolumeID.volumeIdentifier!.isEqual(destinationVolumeID.volumeIdentifier!)
        } catch {
            print("Error while getting the volume ID: \(error)")
            return false
        }
    }
}
