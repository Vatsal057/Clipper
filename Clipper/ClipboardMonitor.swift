import AppKit
import Foundation

// MARK: - ClipboardMonitor

/// Polls NSPasteboard every 0.5s. On change, reads the new content and
/// pushes a ClipboardItem to the store. Self-generated pastes are suppressed
/// by comparing the changeCount against a suppression window.
final class ClipboardMonitor {

    // MARK: Dependencies
    private let store: ClipboardStore
    private var timer: Timer?

    // MARK: State
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private var suppressUntilCount: Int = -1   // set by PasteEngine to ignore its own writes

    // MARK: Init
    init(store: ClipboardStore) {
        self.store = store
    }

    // MARK: - Control

    func start() {
        lastChangeCount = NSPasteboard.general.changeCount
        timer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { [weak self] _ in self?.poll() }
        )
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    /// Call just before Clipper writes to the pasteboard so we don't
    /// record our own paste-back as a new history entry.
    func suppressNext() {
        // The changeCount will increment once after our write.
        // Record the count *now* so we skip count+1.
        suppressUntilCount = NSPasteboard.general.changeCount + 1
    }

    // MARK: - Private

    private func poll() {
        let pb    = NSPasteboard.general
        let count = pb.changeCount
        guard count != lastChangeCount else { return }
        defer { lastChangeCount = count }

        // Skip self-generated writes
        if count == suppressUntilCount {
            suppressUntilCount = -1
            return
        }

        let item = buildItem(from: pb)
        DispatchQueue.main.async { [weak self] in
            self?.store.prepend(item)
        }
    }

    private func buildItem(from pb: NSPasteboard) -> ClipboardItem {
        // Capture source app before we touch anything
        let source   = NSWorkspace.shared.frontmostApplication
        let bundleID = source?.bundleIdentifier
        let appName  = source?.localizedName
        let iconData = source.flatMap { appIconPNG(for: $0) }

        // Prefer plain text; fall back to image
        if let text = pb.string(forType: .string), !text.isEmpty {
            return ClipboardItem(
                content:      .text(text),
                appBundleID:  bundleID,
                appName:      appName,
                appIconData:  iconData
            )
        }

        if let imgData = pb.data(forType: .tiff) ?? pb.data(forType: .png),
           let image   = NSImage(data: imgData),
           let pngData = image.pngRepresentation {
            return ClipboardItem(
                content:     .image(pngData),
                appBundleID: bundleID,
                appName:     appName,
                appIconData: iconData
            )
        }

        // Fallback: generic text for non-string types
        let typeDesc = pb.types?.first?.rawValue ?? "unknown"
        return ClipboardItem(
            content:     .text("[Binary: \(typeDesc)]"),
            appBundleID: bundleID,
            appName:     appName,
            appIconData: iconData
        )
    }

    /// Returns a 16×16 PNG of the app's icon, or nil on failure.
    private func appIconPNG(for app: NSRunningApplication) -> Data? {
        guard let icon = app.icon else { return nil }
        let size = NSSize(width: 16, height: 16)
        let img  = NSImage(size: size)
        img.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: size),
                  from: .zero, operation: .copy, fraction: 1)
        img.unlockFocus()
        return img.pngRepresentation
    }
}

// MARK: - NSImage convenience

private extension NSImage {
    var pngRepresentation: Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap   = NSBitmapImageRep(data: tiffData)
        else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
