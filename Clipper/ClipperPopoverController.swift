import AppKit
import SwiftUI

// MARK: - ClipperPopoverController

/// Manages the NSPopover that hosts ClipperPanel.
/// Supports two open modes:
///   - anchored to the menu-bar status item (click)
///   - floating near the mouse cursor (global hotkey)
final class ClipperPopoverController: NSObject, NSPopoverDelegate {

    // MARK: Dependencies
    private let store:  ClipboardStore
    private let engine: PasteEngine

    // MARK: State
    private var popover:     NSPopover?
    private var cursorPanel: NSPanel?   // used for cursor-positioned display
    private var globalEventMonitor: Any?
    private(set) var previousApp: NSRunningApplication?

    // MARK: Init
    init(store: ClipboardStore, engine: PasteEngine) {
        self.store  = store
        self.engine = engine
    }

    // MARK: - Status-bar toggle (click on icon)

    func toggleAtStatusBar(button: NSStatusBarButton) {
        if isShown { close(); return }

        previousApp = NSWorkspace.shared.frontmostApplication
        let panel = makePanel()

        let pop = NSPopover()
        pop.contentSize           = NSSize(width: 340, height: 500)
        pop.behavior              = .transient
        pop.animates              = true
        pop.contentViewController = NSHostingController(rootView: panel)
        pop.delegate              = self
        pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover = pop
    }

    // MARK: - Cursor-positioned toggle (global hotkey)

    func toggleAtCursor(mousePosition: NSPoint) {
        NSLog("[Clipper] toggleAtCursor called with position: \(mousePosition)")
        if isShown { 
            NSLog("[Clipper] isShown is true, closing.")
            close()
            return 
        }

        previousApp = NSWorkspace.shared.frontmostApplication
        NSLog("[Clipper] previousApp: \(previousApp?.localizedName ?? "none")")

        // Build a floating panel positioned near the cursor
        let panelWidth:  CGFloat = 340
        let panelHeight: CGFloat = 480
        let offset:      CGFloat = 12

        // Find which screen the cursor is on
        let screen = NSScreen.screens.first { NSMouseInRect(mousePosition, $0.frame, false) }
            ?? NSScreen.main ?? NSScreen.screens[0]

        // Position: cursor x centred, above cursor; clamp to screen
        var origin = NSPoint(
            x: mousePosition.x - panelWidth / 2,
            y: mousePosition.y + offset
        )
        origin.x = min(max(origin.x, screen.visibleFrame.minX + 4),
                       screen.visibleFrame.maxX - panelWidth - 4)
        origin.y = min(max(origin.y, screen.visibleFrame.minY + 4),
                       screen.visibleFrame.maxY - panelHeight - 4)

        let panel = NSPanel(
            contentRect: NSRect(origin: origin, size: CGSize(width: panelWidth, height: panelHeight)),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        panel.isReleasedWhenClosed = false
        panel.level                = .popUpMenu
        panel.backgroundColor      = .clear
        panel.isOpaque             = false
        panel.hasShadow            = true
        panel.collectionBehavior   = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let swiftUIPanel = makePanel()
        let hc = NSHostingController(rootView: swiftUIPanel)
        hc.view.frame = NSRect(origin: .zero, size: CGSize(width: panelWidth, height: panelHeight))
        panel.contentView = hc.view

        // Dismiss on click-outside via a monitor
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closeCursorPanel()
        }

        NSLog("[Clipper] Displaying panel...")
        panel.orderFrontRegardless()
        panel.makeKey()
        cursorPanel = panel
    }

    // MARK: - Shared

    var isShown: Bool {
        (popover?.isShown == true) || (cursorPanel != nil)
    }

    func close() {
        popover?.close()
        closeCursorPanel()
    }

    private func closeCursorPanel() {
        if let m = globalEventMonitor {
            NSEvent.removeMonitor(m)
            globalEventMonitor = nil
        }
        cursorPanel?.close()
        cursorPanel = nil
    }

    private func makePanel() -> ClipperPanel {
        ClipperPanel(
            store: store,
            onPaste: { [weak self] item in
                guard let self else { return }
                self.close()
                self.engine.paste(item: item, into: self.previousApp)
            },
            onClose: { [weak self] in
                self?.close()
            }
        )
    }

    // MARK: - NSPopoverDelegate

    func popoverDidClose(_ notification: Notification) {
        popover = nil
    }
}
