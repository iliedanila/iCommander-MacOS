//
//  ViewController.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 29/09/2020.
//

import Cocoa

// MARK: - NSViewController
class ViewController: NSViewController {

    @IBOutlet var leftTable: NSTableView!
    @IBOutlet var rightTable: NSTableView!
    @IBOutlet var tableMenu: NSMenu!
    @IBOutlet var leftPathStackView: NSStackView!
    @IBOutlet var rightPathStackView: NSStackView!
    @IBOutlet var leftHomeButton: NSButton!
    @IBOutlet var rightHomeButton: NSButton!
    @IBOutlet var F3ViewButton: NSButton!
    @IBOutlet var F4EditButton: NSButton!
    @IBOutlet var F5CopyButton: NSButton!
    @IBOutlet var F6MoveButton: NSButton!
    @IBOutlet var F7NewFolderButton: NSButton!
    @IBOutlet var F8DeleteButton: NSButton!
    @IBOutlet var leftDriveButton: NSPopUpButton!
    @IBOutlet var rightDriveButton: NSPopUpButton!
    @IBOutlet var leftBackButton: NSButton!
    @IBOutlet var leftForwardButton: NSButton!
    @IBOutlet var rightBackButton: NSButton!
    @IBOutlet var rightForwardButton: NSButton!
    
    var tableToPath: [NSTableView : NSStackView] = [:]
    var leftTableDataSource: TableDataSource = TableDataSource(.Left)
    var rightTableDataSource: TableDataSource = TableDataSource(.Right)
    var leftLocationHistory: LocationHistory = LocationHistory(.Left)
    var rightLocationHistory: LocationHistory = LocationHistory(.Right)
    var tableToDataSource: [NSTableView : TableDataSource] = [:]
    var tableToLocationHistory: [NSTableView : LocationHistory] = [:]
    var indexDrivePath: [Int : URL] = [:]
    var currentActiveTable: NSTableView? = nil
    var fileOperations = FileOperations()
    var rowIndexForContexMenu: Int = -1
    var copyOperationsAlerts: [String:NSAlert] = [:]
    
    var progressWindowController: ProgressWindowController? = nil
    var progressViewController: ProgressViewController? = nil
    
    @IBAction func handleDriveButton(_ sender: NSPopUpButton) {
        if sender == leftDriveButton {
            leftTableDataSource.currentUrl = indexDrivePath[sender.indexOfSelectedItem]!
        } else {
            rightTableDataSource.currentUrl = indexDrivePath[sender.indexOfSelectedItem]!
        }
    }
    
    @IBAction func functionButtonClicked(_ sender: NSButton) {
        if sender == F5CopyButton {
            handleF5()
        } else if sender == F6MoveButton {
            handleF6()
        } else if sender == F7NewFolderButton {
            handleF7()
        }
    }
    
    @IBAction func tableClicked(_ sender: NSTableView) {
        if sender.clickedRow == -1 && sender.clickedColumn != -1 {
            if let tableData = tableToDataSource[sender] {
                let sortDescriptor = sender.sortDescriptors[0]
                if let key = sortDescriptor.key {
                    tableData.sort(key, sortDescriptor.ascending)
                }
                sender.reloadData()
            }
        }
        currentActiveTable = sender
    }
    
    @IBAction func tableDoubleClick(_ sender: NSTableView) {
        if sender.clickedRow == -1 {
            return
        }
        
        if let tableData = tableToDataSource[sender], let locationHistory = tableToLocationHistory[sender] {
            
            let item = tableData.tableElements[sender.clickedRow]
            if item.isDirectory && !item.isPackage! {
                tableData.currentUrl = item.url
                locationHistory.addDirectoryToHistory(item.url)
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
    }

    @IBAction func handleNavigate(_ sender: NSButton) {
        switch sender {
        case leftBackButton:
            leftLocationHistory.handleBackPressed()
        case leftForwardButton:
            leftLocationHistory.handleForwardPressed()
        case rightBackButton:
            rightLocationHistory.handleBackPressed()
        case rightForwardButton:
            rightLocationHistory.handleForwardPressed()
        default:
            print("Unknown button")
        }
    }
    
    @IBAction func homeButtonClicked(_ sender: NSButton) {
        if sender == leftHomeButton {
            leftTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        } else {
            rightTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        }
    }
    
    @IBAction func cellEditAction(_ sender: Any) {
        if let textField = sender as? NSTextField {
            let activeTable = currentActiveTable == leftTable ? leftTable : rightTable
            let dataSource = tableToDataSource[activeTable!]!
            let element = dataSource.tableElements[activeTable!.selectedRow]
            print("Probably editing \(element.name)")
            
            fileOperations.rename(element.url, dataSource.currentUrl, textField.stringValue)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableToPath[leftTable] = leftPathStackView
        tableToPath[rightTable] = rightPathStackView
        tableToDataSource[leftTable] = leftTableDataSource
        tableToDataSource[rightTable] = rightTableDataSource
        tableToLocationHistory[leftTable] = leftLocationHistory
        tableToLocationHistory[rightTable] = rightLocationHistory
        
        leftTableDataSource.delegate = self
        rightTableDataSource.delegate = self
        leftLocationHistory.delegate = self
        rightLocationHistory.delegate = self
        fileOperations.delegate = self
        
        leftTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        rightTableDataSource.currentUrl = FileManager.default.homeDirectoryForCurrentUser
        
        leftLocationHistory.addDirectoryToHistory(leftTableDataSource.currentUrl)
        rightLocationHistory.addDirectoryToHistory(rightTableDataSource.currentUrl)
        
        if let leftTableView = leftTable as? TableView, let rightTableView = rightTable as? TableView {
            leftTableView.tableViewDelegate = self
            rightTableView.tableViewDelegate = self
            
            leftTableDataSource.sort(Constants.NameColumn, true)
            rightTableDataSource.sort(Constants.NameColumn, true)
        }
        
        leftTable.rowSizeStyle = .medium
        rightTable.rowSizeStyle = .medium
        
        populateDriveList()
                
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(handleDriveChange), name: NSWorkspace.didMountNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleDriveChange), name: NSWorkspace.didUnmountNotification, object: nil)
    }
    
    func populateDriveList() {
        leftDriveButton.removeAllItems()
        rightDriveButton.removeAllItems()
        indexDrivePath.removeAll()
        
        let keys = Set<URLResourceKey>([.volumeNameKey, .isVolumeKey, .volumeIsBrowsableKey])
        let option: FileManager.VolumeEnumerationOptions = .skipHiddenVolumes
        let fileManager = FileManager.default
        
        if let mountedVolumesUrls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: option) {
            var index: Int = 0
            for volumeUrl in mountedVolumesUrls {
                do {
                    let resourceValues = try volumeUrl.resourceValues(forKeys: keys)
                    if resourceValues.isVolume != nil && resourceValues.isVolume == true {
                        leftDriveButton.addItem(withTitle: resourceValues.volumeName!)
                        rightDriveButton.addItem(withTitle: resourceValues.volumeName!)
                        indexDrivePath[index] = volumeUrl
                        index = index + 1
                    }
                } catch {
                    print(error)
                }
            }
        }
    }

    func handleMaximize() {
        resizeTableViewColumns(leftTable)
        resizeTableViewColumns(rightTable)
        
        leftTable.needsDisplay = true
        rightTable.needsDisplay = true
        
        leftTable.reloadData()  // Important to have the row height properly
        rightTable.reloadData() // computed because depend on table visible rect.
    }
    
    func resizeTableViewColumns(_ tableView: NSTableView) {
        let tableWidth: CGFloat = tableView.visibleRect.width
        
        tableView.tableColumns[0].width = 5 * tableWidth / 8
        tableView.tableColumns[1].width = 2 * tableWidth / 8
        tableView.tableColumns[2].width = tableWidth / 8
    }
    
    @objc func handleDriveChange(_ notification: NSNotification) {
        populateDriveList()
    }
}

