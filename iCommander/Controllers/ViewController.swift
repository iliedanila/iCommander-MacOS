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
    @IBOutlet var F3ViewButton: NSButton!
    @IBOutlet var F4EditButton: NSButton!
    @IBOutlet var F5CopyButton: NSButton!
    @IBOutlet var F6MoveButton: NSButton!
    @IBOutlet var F7NewFolderButton: NSButton!
    @IBOutlet var F8DeleteButton: NSButton!
    @IBOutlet var leftShowHiddenFiles: NSButton!
    @IBOutlet var rightShowHiddenFiles: NSButton!
    @IBOutlet var leftVolumesStackView: NSStackView!
    @IBOutlet var rightVolumesStackView: NSStackView!
    @IBOutlet var favoritesStackView: NSStackView!
    @IBOutlet var leftPath: NSTextField!
    @IBOutlet var rightPath: NSTextField!
    
    var leftTableDataSource: TableDataSource = TableDataSource(.Left)
    var rightTableDataSource: TableDataSource = TableDataSource(.Right)
    
    var leftTableData: TableViewData? = nil
    var rightTableData: TableViewData? = nil
    
    var tableToDataSource: [NSTableView : TableDataSource] = [:]
    var indexDrivePath: [Int : URL] = [:]
    var currentActiveTable: NSTableView? = nil
    var fileOperations = FileOperations()
    var rowIndexForContexMenu: Int = -1
    var tableViewForContextMenu: NSTableView? = nil
    var copyOperationsAlerts: [String:NSAlert] = [:]
    
    var progressWindowController: ProgressWindowController? = nil
    var progressViewController: ProgressViewController? = nil
    
    let context = (NSApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    @IBAction func showHiddenFilesToggled(_ sender: NSButton) {
        let isOn = sender.state == .on
        if sender == leftShowHiddenFiles {
            leftTableDataSource.showHiddenFiles = isOn
            leftTableData?.showHiddenFiles = isOn
            leftTable.reloadData()
        } else {
            rightTableDataSource.showHiddenFiles = isOn
            rightTableData?.showHiddenFiles = isOn
            rightTable.reloadData()
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
        
        if let tableData = tableToDataSource[sender] {
            
            let item = tableData.tableElements[sender.clickedRow]
            if item.isDirectory && !item.isPackage! {
                tableData.currentUrl = item.url
            } else {
                NSWorkspace.shared.open(item.url)
            }
        }
    }

    @IBAction func cellEditAction(_ sender: Any) {
        if let textField = sender as? NSTextField {
            let activeTable = currentActiveTable == leftTable ? leftTable : rightTable
            let dataSource = tableToDataSource[activeTable!]!
            let element = dataSource.tableElements[activeTable!.selectedRow]
            
            fileOperations.rename(element.url, dataSource.currentUrl, textField.stringValue)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableToDataSource[leftTable] = leftTableDataSource
        tableToDataSource[rightTable] = rightTableDataSource
        
        leftTableDataSource.delegate = self
        rightTableDataSource.delegate = self
        fileOperations.delegate = self
        
        fetchFromContext()
        
        if let leftTableView = leftTable as? TableView, let rightTableView = rightTable as? TableView {
            leftTableView.tableViewDelegate = self
            rightTableView.tableViewDelegate = self
            
            leftTableDataSource.sort(Constants.NameColumn, true)
            rightTableDataSource.sort(Constants.NameColumn, true)
        }
        
        leftTable.rowSizeStyle = .medium
        rightTable.rowSizeStyle = .medium
        
        populateVolumeButtons()
                
        let notificationCenter = NSWorkspace.shared.notificationCenter
        notificationCenter.addObserver(self, selector: #selector(handleDriveChange), name: NSWorkspace.didMountNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(handleDriveChange), name: NSWorkspace.didUnmountNotification, object: nil)
    }
    
    func fetchFromContext() {
        do {
            let contextItems = try context.fetch(TableViewData.fetchRequest())
            for contextItem in contextItems {
                if let tableData = contextItem as? TableViewData {
                    if tableData.isOnLeftSide {
                        leftTableData = tableData
                    } else {
                        rightTableData = tableData
                    }
                }
            }
            
            leftTableDataSource.currentUrl = leftTableData!.currentUrlDBValue!
            leftTableDataSource.showHiddenFiles = leftTableData!.showHiddenFiles
            rightTableDataSource.currentUrl = rightTableData!.currentUrlDBValue!
            rightTableDataSource.showHiddenFiles = rightTableData!.showHiddenFiles
            
            if leftTableData!.showHiddenFiles {
                leftShowHiddenFiles.state = .on
            }
            if rightTableData!.showHiddenFiles {
                rightShowHiddenFiles.state = .on
            }
        } catch  {
            createTableData()
            self.saveContext()
        }
    }
    
    func createTableData() {
        leftTableData = TableViewData(context: context)
        leftTableData?.isOnLeftSide = true
        leftTableData?.showHiddenFiles = false
        leftTableData?.currentUrlDBValue = FileManager.default.homeDirectoryForCurrentUser
        
        rightTableData = TableViewData(context: context)
        rightTableData?.isOnLeftSide = false
        rightTableData?.showHiddenFiles = false
        rightTableData?.currentUrlDBValue = FileManager.default.homeDirectoryForCurrentUser
        
        leftTableDataSource.currentUrl = leftTableData!.currentUrlDBValue!
        leftTableDataSource.showHiddenFiles = leftTableData!.showHiddenFiles
        rightTableDataSource.currentUrl = rightTableData!.currentUrlDBValue!
        rightTableDataSource.showHiddenFiles = rightTableData!.showHiddenFiles

    }
    
    func saveContext() {
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func populateVolumeButtons() {
        clearVolumesStackViews()
        
        let resourceValuesList = getMountedVolumesResourceValues()
        
        leftVolumesStackView.addView(createHomeButton(.Left), in: .trailing)
        rightVolumesStackView.addView(createHomeButton(.Right), in: .trailing)
        
        for resourceValues in resourceValuesList {
            let leftButton = createDriveButton(resourceValues, .Left)
            let rightButton = createDriveButton(resourceValues, .Right)
            
            leftVolumesStackView.addView(leftButton, in: .trailing)
            rightVolumesStackView.addView(rightButton, in: .trailing)
        }
    }
    
    func clearVolumesStackViews() {
        let leftStackViewItems = leftVolumesStackView.views
        for item in leftStackViewItems {
            leftVolumesStackView.removeView(item)
        }
        
        let rightStackViewItems = rightVolumesStackView.views
        for item in rightStackViewItems {
            rightVolumesStackView.removeView(item)
        }
    }
    
    func createHomeButton(_ locationOnScreen: LocationOnScreen) -> DriveButton {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let homeImage = NSWorkspace.shared.icon(forFile: homeURL.path)
        let button = DriveButton(title: "Home", image: homeImage, target: self, action: #selector(driveButtonPressed(_:)))
        button.imagePosition = .imageLeading
        button.setButtonType(.momentaryPushIn)
        button.isBordered = true
        button.state = .off
        button.drivePath = homeURL.path
        button.locationOnScreen = locationOnScreen
        
        return button
    }
    
    func getMountedVolumesResourceValues() -> [URLResourceValues] {
        
        var result: [URLResourceValues] = []
        
        let fileManager = FileManager.default
        let keys = Set<URLResourceKey>([.volumeNameKey, .isVolumeKey, .volumeIsBrowsableKey, .customIconKey, .effectiveIconKey, .pathKey])
        let option: FileManager.VolumeEnumerationOptions = .skipHiddenVolumes
        
        if let mountedVolumesUrls = fileManager.mountedVolumeURLs(includingResourceValuesForKeys: Array(keys), options: option) {
            for volumeUrl in mountedVolumesUrls {
                do {
                    let resourceValues = try volumeUrl.resourceValues(forKeys: keys)
                    result.append(resourceValues)
                } catch {
                    print(error)
                }
            }
        }
        return result
    }
    
    func createDriveButton(_ resourceValues: URLResourceValues, _ locationOnScreen: LocationOnScreen) -> DriveButton {
        
        let button = DriveButton(title: resourceValues.volumeName!, image: resourceValues.effectiveIcon as! NSImage, target: self, action: #selector(driveButtonPressed(_:)))
        button.imagePosition = .imageLeading
        button.setButtonType(.momentaryPushIn)
        button.isBordered = true
        button.state = .off
        button.drivePath = resourceValues.path
        button.locationOnScreen = locationOnScreen
        
        return button
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
        tableView.tableColumns[2].width = tableWidth / 8 - 1
    }
    
    @objc func handleDriveChange(_ notification: NSNotification) {
        populateVolumeButtons()
    }
    
    @objc func driveButtonPressed(_ sender: Any?)
    {
        if let button = sender as? DriveButton,
           let locationOnScreen = button.locationOnScreen {
            
            let tableView = locationOnScreen == .Left ? leftTable : rightTable
            let dataSource = tableToDataSource[tableView!]!
            dataSource.currentUrl = URL(fileURLWithPath: button.drivePath!)
        }
    }
}

