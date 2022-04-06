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
    @IBOutlet var leftShowHiddenFiles: NSButton!
    @IBOutlet var rightShowHiddenFiles: NSButton!
    @IBOutlet var leftVolumesStackView: NSStackView!
    @IBOutlet var rightVolumesStackView: NSStackView!
    @IBOutlet var favoritesStackView: NSStackView!
    @IBOutlet var leftPath: NSTextField!
    @IBOutlet var rightPath: NSTextField!
    @IBOutlet var addRemoveFavorite: NSButton!
    
    var leftTableDataSource: TableDataSource = TableDataSource(.Left)
    var rightTableDataSource: TableDataSource = TableDataSource(.Right)
    
    var leftTableData: TableViewData? = nil
    var rightTableData: TableViewData? = nil
    
    var favorites: Favorites? = nil
    
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
        refreshAddRemoveFavButton(tableToDataSource[sender]!.currentURL)
    }
    
    @IBAction func tableDoubleClick(_ sender: NSTableView) {
        if sender.clickedRow == -1 {
            return
        }
        
        if let tableData = tableToDataSource[sender] {
            
            let item = tableData.tableElements[sender.clickedRow]
            if item.isDirectory && !item.isPackage! {
                tableData.currentURL = item.url
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
            
            fileOperations.rename(element.url, dataSource.currentURL, textField.stringValue)
        }
    }
    
    
    @IBAction func pathEdited(_ sender: NSTextField) {
        let isPathValid = FileManager.default.fileExists(atPath: sender.stringValue)
        let tableView = sender == leftPath ? leftTable : rightTable
        let dataSource = tableToDataSource[tableView!]!
        
        var isNewPathOK = false
        
        if isPathValid {
            let url = URL(fileURLWithPath: sender.stringValue)
            
            if url.hasDirectoryPath {
                isNewPathOK = true
                dataSource.currentURL = url
            }
        }
        
        if !isNewPathOK {
            sender.stringValue = dataSource.currentURL.path
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
        
        focusNextTable(rightTable)
    }
    
    @IBAction func addRemoveFavorite(_ sender: Any) {
        if let button = sender as? NSButton {
            
            let dataSource = tableToDataSource[currentActiveTable!]!
            
            switch button.title {
            case "+":
                favorites?.favURLs?.append(dataSource.currentURL)
            case "-":
                if let index = favorites?.favURLs?.firstIndex(of: dataSource.currentURL) {
                    favorites?.favURLs?.remove(at: index)
                }
            default:
                break;
            }
            
            saveContext()
            fetchFavorites()
            refreshAddRemoveFavButton(dataSource.currentURL)
        }
    }
    
    func fetchFromContext() {
        fetchTableData()
        fetchFavorites()
    }
    
    func fetchTableData() {
        do {
            let tableViewDataItems = try context.fetch(TableViewData.fetchRequest())
            
            if tableViewDataItems.count != 0 {
                for tableViewDataItem in tableViewDataItems {
                    let tableData = tableViewDataItem
                    if tableData.isOnLeftSide {
                        leftTableData = tableData
                    } else {
                        rightTableData = tableData
                    }
                }
                
                leftTableDataSource.currentURL = leftTableData!.currentUrlDBValue!
                leftTableDataSource.showHiddenFiles = leftTableData!.showHiddenFiles
                rightTableDataSource.currentURL = rightTableData!.currentUrlDBValue!
                rightTableDataSource.showHiddenFiles = rightTableData!.showHiddenFiles
                
                if leftTableData!.showHiddenFiles {
                    leftShowHiddenFiles.state = .on
                }
                if rightTableData!.showHiddenFiles {
                    rightShowHiddenFiles.state = .on
                }
            } else {
                createTableData()
            }
        } catch  {
            createTableData()
            self.saveContext()
        }
    }
    
    func fetchFavorites() {
        do {
            let favoritesItems = try context.fetch(Favorites.fetchRequest())
            if !favoritesItems.isEmpty {
                favorites = favoritesItems[0]
                addFavoritesButtons(favorites)
            } else {
                addFavoritesButtons(nil)
                saveContext()
            }
        } catch {
            addFavoritesButtons(nil)
            saveContext()
        }
    }
    
    func addFavoritesButtons(_ favoritesDB: Favorites?) {
        if favoritesDB == nil {
            favorites = Favorites(context: context)
            
            let applicationsFolderURL = FileManager.default.urls(for: .applicationDirectory, in: .localDomainMask)[0]
            let documentsFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let downloadsFolderURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
            
            favorites?.favURLs = []
            favorites?.favURLs?.append(applicationsFolderURL)
            favorites?.favURLs?.append(documentsFolderURL)
            favorites?.favURLs?.append(downloadsFolderURL)
        }
        
        clearFavoritesStackView()
        
        for url in favorites!.favURLs! {
            favoritesStackView.addView(createFavButton(url), in: .trailing)
        }
    }
    
    func clearFavoritesStackView() {
        for view in favoritesStackView.views {
            favoritesStackView.removeView(view)
        }
        
        favoritesStackView.addView(NSTextField(labelWithString: "Favorites: "), in: .trailing)
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
        
        leftTableDataSource.currentURL = leftTableData!.currentUrlDBValue!
        leftTableDataSource.showHiddenFiles = leftTableData!.showHiddenFiles
        rightTableDataSource.currentURL = rightTableData!.currentUrlDBValue!
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
        
        leftVolumesStackView.addView(NSTextField(labelWithString: "Volumes: "), in: .trailing)
        rightVolumesStackView.addView(NSTextField(labelWithString: "Volumes: "), in: .trailing)
        
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
    
    func createFavButton(_ url: URL) -> ButtonWithPath {
        let image = NSWorkspace.shared.icon(forFile: url.path)
        let button = ButtonWithPath(title: url.lastPathComponent, image: image, target: self, action: #selector(pathButtonPressed(_:)))
        button.imagePosition = .imageLeading
        button.setButtonType(.momentaryPushIn)
        button.isBordered = true
        button.state = .off
        button.path = url.path
        
        return button
    }
    
    func refreshAddRemoveFavButton(_ url: URL) {
        if (favorites?.favURLs?.firstIndex(of: url)) != nil {
            addRemoveFavorite.title = "-"
            if #available(OSX 11.0, *) {
                addRemoveFavorite.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: nil)
            }
        } else {
            addRemoveFavorite.title = "+"
            if #available(OSX 11.0, *) {
                addRemoveFavorite.image = NSImage(systemSymbolName: "star", accessibilityDescription: nil)
            }
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
        button.path = homeURL.path
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
        button.path = resourceValues.path
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
        leftTableDataSource.checkPathIsStillValid()
        rightTableDataSource.checkPathIsStillValid()
    }
    
    @objc func pathButtonPressed(_ sender: Any?) {
        if let button = sender as? ButtonWithPath {
            let dataSource = tableToDataSource[currentActiveTable!]!
            dataSource.currentURL = URL(fileURLWithPath: button.path!)
        }
    }
    
    @objc func driveButtonPressed(_ sender: Any?)
    {
        if let button = sender as? DriveButton,
           let locationOnScreen = button.locationOnScreen {
            
            let tableView = locationOnScreen == .Left ? leftTable : rightTable
            let dataSource = tableToDataSource[tableView!]!
            dataSource.currentURL = URL(fileURLWithPath: button.path!)
        }
    }
}

