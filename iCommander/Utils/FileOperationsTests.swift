//
//  FileOperationsTests.swift
//  iCommander-MacOS Tests
//
//  Unit tests for file operations
//  
//  NOTE: This file requires a test target to be set up in Xcode.
//  To use these tests:
//  1. In Xcode, go to File → New → Target
//  2. Choose "Unit Testing Bundle"
//  3. Add this file to that test target
//  4. Make sure your main app target is selected in "Target to be Tested"
//

/*
import XCTest
@testable import iCommander_MacOS

class FileOperationsTests: XCTestCase {
    
    func testFileSize() throws {
        let fileOps = FileOperations()
        
        // Create a temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test.txt")
        
        let testData = "Hello, World!".data(using: .utf8)!
        try testData.write(to: testFile)
        
        defer {
            try? FileManager.default.removeItem(at: testFile)
        }
        
        let size = fileOps.getFileSize(testFile)
        XCTAssertEqual(size, UInt64(testData.count), "File size should match data size")
    }
    
    func testSameVolume() throws {
        let fileOps = FileOperations()
        
        let tempDir = FileManager.default.temporaryDirectory
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        
        // Both should be on the same volume (typically)
        let areSame = fileOps.isOnTheSameVolume(tempDir, homeDir)
        XCTAssertTrue(areSame, "Temp and home directories should be on the same volume")
    }
}

class TableDataSourceTests: XCTestCase {
    
    func testSortByName() throws {
        let dataSource = TableDataSource(.Left)
        dataSource.currentURL = FileManager.default.homeDirectoryForCurrentUser
        
        dataSource.sort(Constants.NameColumn, true)
        
        // Verify sorting (skip first element which is parent folder)
        if dataSource.tableElements.count > 2 {
            let first = dataSource.tableElements[1].name
            let second = dataSource.tableElements[2].name
            XCTAssertLessThanOrEqual(first, second, "Elements should be sorted alphabetically")
        }
    }
    
    func testHiddenFilesToggle() throws {
        let dataSource = TableDataSource(.Left)
        dataSource.currentURL = FileManager.default.homeDirectoryForCurrentUser
        
        let countWithoutHidden = dataSource.tableElements.count
        
        dataSource.showHiddenFiles = true
        
        let countWithHidden = dataSource.tableElements.count
        
        // With hidden files shown, count should be >= without
        XCTAssertGreaterThanOrEqual(countWithHidden, countWithoutHidden, 
                                    "Showing hidden files should not decrease the count")
    }
}
*/

