import AppKit
import SwiftUI

// MARK: - AppDelegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: Core objects
    private let store        = ClipboardStore()
    private lazy var monitor = ClipboardMonitor(store: store)
    private lazy var engine  = PasteEngine(monitor: monitor)
    private lazy var popoverCtrl = ClipperPopoverController(store: store, engine: engine)

    // MARK: UI
    private var statusItem: NSStatusItem?
    private var eventTap:   CFMachPort?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        PasteEngine.requestAccessibilityIfNeeded()
        setupStatusItem()
        setupGlobalHotkey()
        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
    }

    // MARK: - Menu bar icon

    private func setupStatusItem() {
        let item   = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem = item
        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "Clipper"
            )
            button.image?.isTemplate = true
            button.action = #selector(statusIconClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusIconClicked() {
        guard let button = statusItem?.button, let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            let quitItem = NSMenuItem(title: "Quit Clipper", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            quitItem.target = NSApp
            menu.addItem(quitItem)
            
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        } else {
            // Left click
            popoverCtrl.toggleAtStatusBar(button: button)
        }
    }

    // MARK: - Global hotkey (⌘⇧C)

    private func setupGlobalHotkey() {
        let mask: CGEventMask = 1 << CGEventType.keyDown.rawValue
        guard let tap = CGEvent.tapCreate(
            tap:              .cgSessionEventTap,
            place:            .headInsertEventTap,
            options:          .defaultTap,
            eventsOfInterest: mask,
            callback: { _, _, event, refcon -> Unmanaged<CGEvent>? in
                guard let refcon else { return Unmanaged.passRetained(event) }
                let d = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()
                return d.handleKeyEvent(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("[Clipper] CGEventTap failed — grant Accessibility in System Settings.")
            return
        }

        let src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), src, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
    }

    private func handleKeyEvent(_ event: CGEvent) -> Unmanaged<CGEvent>? {
        let prefs = ClipperPreferences.shared
        let hotkeyCode = Int64(prefs.hotkeyCode)
        let relevant = CGEventFlags(rawValue: prefs.hotkeyModifiers)
        
        let flags = event.flags.intersection([.maskCommand, .maskShift, .maskAlternate, .maskControl])
        guard event.getIntegerValueField(.keyboardEventKeycode) == hotkeyCode,
              flags == relevant
        else {
            return Unmanaged.passRetained(event)
        }

        // Capture mouse position before dispatching to main
        let mousePos = NSEvent.mouseLocation

        DispatchQueue.main.async { [weak self] in
            self?.popoverCtrl.toggleAtCursor(mousePosition: mousePos)
        }
        return nil   // consume — don't copy
    }
}

// MARK: - Entry point

@main
struct ClipperApp {
    static func main() {
        let app      = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
