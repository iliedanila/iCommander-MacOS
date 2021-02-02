//
//  TableViewData+CoreDataProperties.swift
//  iCommander
//
//  Created by Ilie Danila on 01.02.2021.
//
//

import Foundation
import CoreData


extension TableViewData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TableViewData> {
        return NSFetchRequest<TableViewData>(entityName: "TableViewData")
    }

    @NSManaged public var currentUrlDBValue: URL?
    @NSManaged public var isOnLeftSide: Bool
    @NSManaged public var showHiddenFiles: Bool

}

extension TableViewData : Identifiable {

}
