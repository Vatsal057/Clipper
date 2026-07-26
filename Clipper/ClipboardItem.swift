import Foundation
import AppKit

// MARK: - Clipboard Content

/// The actual data stored for a clipboard entry.
enum ClipboardContent: Codable {
    case text(String)
    case image(Data)  // PNG representation

    /// Short preview string for display in the UI.
    var preview: String {
        switch self {
        case .text(let s):
            return s
        case .image:
            return "[Image]"
        }
    }

    var isImage: Bool {
        if case .image = self { return true }
        return false
    }
}

// MARK: - Clipboard Item

/// A single entry in the clipboard history.
struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: ClipboardContent
    let appBundleID: String?   // Bundle ID of the app that wrote to the clipboard
    let appName: String?       // Human-readable app name
    let appIconData: Data?     // 16×16 PNG of the source app icon
    let date: Date
    var pinned: Bool

    init(
        id: UUID = UUID(),
        content: ClipboardContent,
        appBundleID: String? = nil,
        appName: String? = nil,
        appIconData: Data? = nil,
        date: Date = Date(),
        pinned: Bool = false
    ) {
        self.id           = id
        self.content      = content
        self.appBundleID  = appBundleID
        self.appName      = appName
        self.appIconData  = appIconData
        self.date         = date
        self.pinned       = pinned
    }

    static func == (lhs: ClipboardItem, rhs: ClipboardItem) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: Helpers

    /// Returns an NSImage from the stored app icon data, or a generic document icon.
    var appIcon: NSImage {
        if let data = appIconData, let img = NSImage(data: data) { return img }
        return NSWorkspace.shared.icon(forFile: "/usr/bin/env")  // generic fallback
    }
}
