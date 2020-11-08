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
    var rowIndexForMenu: Int? = nil
    var leftTableDataSource: TableDataSource = TableDataSource(.Left)
    var rightTableDataSource: TableDataSource = TableDataSource(.Right)
    var leftLocationHistory: LocationHistory = LocationHistory(.Left)
    var rightLocationHistory: LocationHistory = LocationHistory(.Right)
    var tableToDataSource: [NSTableView : TableDataSource] = [:]
    var tableToLocationHistory: [NSTableView : LocationHistory] = [:]
    var indexDrivePath: [Int : URL] = [:]
    var lastSelectedRow: [NSTableView : Int] = [:]
    
    @IBAction func handleDriveButton(_ sender: NSPopUpButton) {
        if sender == leftDriveButton {
            leftTableDataSource.currentUrl = indexDrivePath[sender.indexOfSelectedItem]!
        } else {
            rightTableDataSource.currentUrl = indexDrivePath[sender.indexOfSelectedItem]!
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
    }
    
    @IBAction func tableDoubleClick(_ sender: NSTableView) {
        if sender.clickedRow == -1 {
            return
        }
        
        if let tableData = tableToDataSource[sender], let locationHistory = tableToLocationHistory[sender] {
            let itemURL = tableData.tableElements[sender.clickedRow].url
            if itemURL.hasDirectoryPath {
                tableData.currentUrl = itemURL
                locationHistory.addDirectoryToHistory(itemURL)
            } else {
                NSWorkspace.shared.open(itemURL)
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
        lastSelectedRow[leftTable] = 0
        lastSelectedRow[rightTable] = 0
        
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
        
        if let mountedVolumes = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: [], options: [.skipHiddenVolumes]) {
            
            var index: Int = 0
            for mountedVolume in mountedVolumes {
                leftDriveButton.addItem(withTitle: mountedVolume.lastPathComponent)
                rightDriveButton.addItem(withTitle: mountedVolume.lastPathComponent)
                indexDrivePath[index] = mountedVolume
                index = index + 1
            }
        }
    }

    func handleMaximize() {
        resizeTableViewColumns(leftTable)
        resizeTableViewColumns(rightTable)
    }
    
    func resizeTableViewColumns(_ tableView: NSTableView) {
        var tableWidth: CGFloat = 0
        for column in tableView.tableColumns {
            tableWidth = tableWidth + column.width
        }
        
        tableView.tableColumns[0].width = 5 * tableWidth / 8
        tableView.tableColumns[1].width = 2 * tableWidth / 8
        tableView.tableColumns[2].width = tableWidth / 8
        
        tableView.needsDisplay = true
    }
    
    @objc func handleDriveChange(_ notification: NSNotification) {
        populateDriveList()
    }
}

