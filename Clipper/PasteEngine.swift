import AppKit
import CoreGraphics

// MARK: - PasteEngine

/// Pastes a ClipboardItem back to the application that was frontmost
/// before Clipper's popover opened.
final class PasteEngine {

    private let monitor: ClipboardMonitor

    init(monitor: ClipboardMonitor) {
        self.monitor = monitor
    }

    // MARK: - Accessibility check

    /// Returns true if the user has granted Accessibility permission.
    static var hasAccessibility: Bool {
        AXIsProcessTrusted()
    }

    /// Prompts the user to grant Accessibility access if not already granted.
    static func requestAccessibilityIfNeeded() {
        guard !hasAccessibility else { return }
        let opts: [String: Any] = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(opts as CFDictionary)
    }

    // MARK: - Paste

    /// Writes `item` to the pasteboard and simulates ⌘V in `targetApp`.
    /// `monitor.suppressNext()` is called first so the write doesn't
    /// create a duplicate history entry.
    func paste(item: ClipboardItem, into targetApp: NSRunningApplication?) {
        monitor.suppressNext()

        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let s):
            // Plain-text mode: write only the string type so apps can't pull RTF
            pb.setString(s, forType: .string)
        case .image(let data):
            pb.setData(data, forType: .png)
        }

        // Re-activate the target app, then post ⌘V
        guard let app = targetApp else { return }
        app.activate(options: [])

        // Small delay so the app has focus before the key event lands
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            Self.postCmdV()
        }
    }

    // MARK: - CGEvent ⌘V

    private static func postCmdV() {
        guard hasAccessibility else {
            requestAccessibilityIfNeeded()
            return
        }
        let src = CGEventSource(stateID: .hidSystemState)
        // keyCode 9 = V
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }
}
