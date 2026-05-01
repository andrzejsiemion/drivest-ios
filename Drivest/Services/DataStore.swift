import Foundation
import SwiftData
import os

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Drivest", category: "Persistence")

enum Persistence {
    @discardableResult
    static func save(_ context: ModelContext) -> Bool {
        do {
            try context.save()
            return true
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
            return false
        }
    }
}

extension String {
    /// Parses a Double from user input, accepting both period and the locale decimal separator.
    func parseDouble() -> Double? {
        if let value = Double(self) { return value }
        let sep = Locale.current.decimalSeparator ?? ","
        return Double(replacingOccurrences(of: sep, with: "."))
    }

    /// SF Symbol name appropriate for a file attachment based on its extension.
    var attachmentIconName: String {
        switch (self as NSString).pathExtension.lowercased() {
        case "pdf":             return "doc.richtext"
        case "jpg", "jpeg",
             "png", "heic":    return "photo"
        case "xls", "xlsx":    return "tablecells"
        case "doc", "docx":    return "doc.text"
        default:               return "doc"
        }
    }
}
