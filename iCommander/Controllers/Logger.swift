//
//  Logger.swift
//  iCommander-MacOS
//
//  Centralized logging for debugging and production
//

import Foundation
import os.log

enum LogCategory: String {
    case fileOperations = "FileOperations"
    case coreData = "CoreData"
    case ui = "UI"
    case general = "General"
}

struct AppLogger {
    
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.icommander"
    
    static func log(_ message: String, category: LogCategory = .general, type: OSLogType = .default) {
        let logger = OSLog(subsystem: subsystem, category: category.rawValue)
        os_log("%{public}@", log: logger, type: type, message)
    }
    
    static func error(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .error)
    }
    
    static func debug(_ message: String, category: LogCategory = .general) {
        #if DEBUG
        log(message, category: category, type: .debug)
        #endif
    }
    
    static func info(_ message: String, category: LogCategory = .general) {
        log(message, category: category, type: .info)
    }
}
