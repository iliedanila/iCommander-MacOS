//
//  FileSearch.swift
//  iCommander-MacOS
//
//  Created by Ilie Danila on 2025.
//

import Foundation

struct SearchResult {
    let url: URL
    let relativePath: String
    let name: String
    let isDirectory: Bool
    let size: Int?
    let dateModified: String
}

protocol FileSearchDelegate: AnyObject {
    func searchFoundResults(_ results: [SearchResult])
    func searchCompleted(totalFound: Int, error: Error?)
}

class FileSearch {
    enum State {
        case running
        case stopped
    }

    weak var delegate: FileSearchDelegate?
    var state: State = .stopped
    var maxResults: Int = 10000

    private let searchQueue = DispatchQueue(label: "com.icommander.search", qos: .userInitiated)
    private let batchSize = 100

    func search(query: String, in directory: URL, showHiddenFiles: Bool) {
        state = .running

        searchQueue.async { [weak self] in
            guard let self = self else { return }

            var options: FileManager.DirectoryEnumerationOptions = []
            if !showHiddenFiles {
                options.insert(.skipsHiddenFiles)
            }

            guard let enumerator = FileManager.default.enumerator(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
                options: options
            ) else {
                DispatchQueue.main.async {
                    self.delegate?.searchCompleted(totalFound: 0, error: nil)
                }
                return
            }

            let pattern = self.globToRegex(query)
            var results: [SearchResult] = []
            var totalFound = 0

            while let url = enumerator.nextObject() as? URL {
                if self.state == .stopped {
                    break
                }

                if totalFound >= self.maxResults {
                    break
                }

                let fileName = url.lastPathComponent

                if self.matches(fileName: fileName, pattern: pattern) {
                    let relativePath = url.path.replacingOccurrences(
                        of: directory.path + "/",
                        with: ""
                    )

                    let isDirectory = url.hasDirectoryPath
                    let size = self.getFileSize(url)
                    let dateModified = self.getFileModifiedDate(url)

                    let result = SearchResult(
                        url: url,
                        relativePath: relativePath,
                        name: fileName,
                        isDirectory: isDirectory,
                        size: size,
                        dateModified: dateModified
                    )

                    results.append(result)
                    totalFound += 1

                    if results.count >= self.batchSize {
                        let batch = results
                        DispatchQueue.main.async {
                            self.delegate?.searchFoundResults(batch)
                        }
                        results = []
                    }
                }
            }

            // Send remaining results
            if !results.isEmpty {
                let batch = results
                DispatchQueue.main.async {
                    self.delegate?.searchFoundResults(batch)
                }
            }

            DispatchQueue.main.async {
                self.state = .stopped
                self.delegate?.searchCompleted(totalFound: totalFound, error: nil)
            }
        }
    }

    func cancel() {
        state = .stopped
    }

    // MARK: - Pattern Matching

    private func globToRegex(_ glob: String) -> String {
        var regex = "^"
        for char in glob {
            switch char {
            case "*":
                regex += ".*"
            case "?":
                regex += "."
            case ".":
                regex += "\\."
            case "\\":
                regex += "\\\\"
            case "^", "$", "(", ")", "[", "]", "{", "}", "|", "+":
                regex += "\\\(char)"
            default:
                regex += String(char)
            }
        }
        regex += "$"
        return regex
    }

    private func matches(fileName: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(fileName.startIndex..., in: fileName)
            return regex.firstMatch(in: fileName, options: [], range: range) != nil
        } catch {
            // If regex fails, fall back to simple contains check
            return fileName.lowercased().contains(pattern.lowercased())
        }
    }

    // MARK: - File Attributes

    private func getFileSize(_ forURL: URL) -> Int? {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.fileSizeKey])
            return resourceValues.fileSize
        } catch {
            return nil
        }
    }

    private func getFileModifiedDate(_ forURL: URL) -> String {
        do {
            let resourceValues = try forURL.resourceValues(forKeys: [.contentModificationDateKey])
            if let dateModified = resourceValues.contentModificationDate {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd hh:mm"
                return dateFormatter.string(from: dateModified)
            }
        } catch {
            // Ignore error
        }
        return ""
    }
}
