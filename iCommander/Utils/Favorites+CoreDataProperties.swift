//
//  Favorites+CoreDataProperties.swift
//  iCommander
//
//  Created by Ilie Danila on 17.02.2021.
//
//

import Foundation
import CoreData


extension Favorites {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Favorites> {
        return NSFetchRequest<Favorites>(entityName: "Favorites")
    }

    @NSManaged public var favURLs: [URL]?

}

extension Favorites : Identifiable {

}
