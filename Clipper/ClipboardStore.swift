import Foundation
import AppKit
import Observation

// MARK: - ClipboardStore

/// Observable in-memory + on-disk store for clipboard history.
/// Pinned items persist across restarts; unpinned are ephemeral for privacy.
@Observable
final class ClipboardStore {

    // MARK: Public state (observed by SwiftUI)
    private(set) var items: [ClipboardItem] = []

    // Max items read from preferences each time trim() is called
    private var maxItems: Int { ClipperPreferences.shared.maxHistoryCount }

    // MARK: Persistence
    private let persistURL: URL = {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("Clipper", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("pinned.json")
    }()

    // MARK: Init
    init() {
        loadPinned()
        seedTemplatesIfNeeded()
    }

    // MARK: - Mutations

    /// Prepend a new item to the history, evicting oldest unpinned if over cap.
    func prepend(_ item: ClipboardItem) {
        // De-duplicate: remove identical content that already exists
        items.removeAll { existing in
            switch (existing.content, item.content) {
            case (.text(let a), .text(let b)): return a == b
            case (.image(let a), .image(let b)): return a == b
            default: return false
            }
        }
        items.insert(item, at: 0)
        trim()
        savePinned()

        // Optional copy sound
        if ClipperPreferences.shared.soundOnCopy {
            NSSound(named: "Pop")?.play()
        }
    }

    /// Toggle pin state for the item with the given id.
    func togglePin(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].pinned.toggle()
        savePinned()
    }

    /// Delete a specific item.
    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        savePinned()
    }

    /// Clear all unpinned items.
    func clearUnpinned() {
        items.removeAll { !$0.pinned }
        savePinned()
    }

    // MARK: - Quick Templates seeding

    /// On very first launch, seed the store with pinned quick templates.
    private func seedTemplatesIfNeeded() {
        let key = "templatesSeeded_v2"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        for tmpl in QuickTemplates.defaults.reversed() {
            let item = ClipboardItem(
                content:    .text(tmpl.content),
                appBundleID: nil,
                appName:    "Quick Template",
                appIconData: nil,
                pinned:     true
            )
            items.insert(item, at: 0)
        }
        savePinned()
    }

    // MARK: - Private helpers

    private func trim() {
        guard items.count > maxItems else { return }
        var unpinnedIndices: [Int] = items.indices
            .filter { !items[$0].pinned }
            .reversed()
        var cursor = 0
        while items.count > maxItems, cursor < unpinnedIndices.count {
            items.remove(at: unpinnedIndices[cursor])
            cursor += 1
        }
    }

    // MARK: - Persistence

    private func savePinned() {
        let pinned = items.filter { $0.pinned }
        guard let data = try? JSONEncoder().encode(pinned) else {
            print("[ClipboardStore] Failed to encode pinned items")
            return
        }
        do {
            try data.write(to: persistURL, options: .atomic)
        } catch {
            print("[ClipboardStore] Failed to write pinned items: \(error)")
        }
    }

    private func loadPinned() {
        guard
            let data  = try? Data(contentsOf: persistURL),
            let pinned = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { return }
        items = pinned
    }
}
