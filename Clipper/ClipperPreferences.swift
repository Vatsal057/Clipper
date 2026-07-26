import Foundation
import AppKit
import ServiceManagement

// MARK: - ClipperPreferences
// Persists user settings in UserDefaults under the app's domain.

final class ClipperPreferences: ObservableObject {

    static let shared = ClipperPreferences()

    // MARK: - Keys
    private enum Key: String {
        case launchAtLogin      = "launchAtLogin"
        case soundOnCopy        = "soundOnCopy"
        case maxHistoryCount    = "maxHistoryCount"
        case hotkeyCode         = "hotkeyCode"
        case hotkeyModifiers    = "hotkeyModifiers"
        case appearance         = "appearance"
        case showAppIcons       = "showAppIcons"
        case pasteAutomatically = "pasteAutomatically"
    }

    // MARK: - Exposed settings (published for SwiftUI bindings)

    @Published var launchAtLogin: Bool {
        didSet { save(.launchAtLogin, launchAtLogin); applyLaunchAtLogin() }
    }

    @Published var soundOnCopy: Bool {
        didSet { save(.soundOnCopy, soundOnCopy) }
    }

    @Published var maxHistoryCount: Int {
        didSet { save(.maxHistoryCount, maxHistoryCount) }
    }

    @Published var hotkeyCode: Int {
        didSet { save(.hotkeyCode, hotkeyCode) }
    }

    @Published var hotkeyModifiers: UInt64 {
        didSet { save(.hotkeyModifiers, hotkeyModifiers) }
    }

    @Published var appearance: String {
        didSet { save(.appearance, appearance) }
    }

    @Published var showAppIcons: Bool {
        didSet { save(.showAppIcons, showAppIcons) }
    }

    @Published var pasteAutomatically: Bool {
        didSet { save(.pasteAutomatically, pasteAutomatically) }
    }

    // MARK: - Init

    private init() {
        let d = UserDefaults.standard
        launchAtLogin      = d.bool(forKey: Key.launchAtLogin.rawValue)
        soundOnCopy        = d.object(forKey: Key.soundOnCopy.rawValue) == nil
                               ? true
                               : d.bool(forKey: Key.soundOnCopy.rawValue)
        maxHistoryCount    = { let v = d.integer(forKey: Key.maxHistoryCount.rawValue); return v == 0 ? 100 : v }()
        
        hotkeyCode         = { let v = d.integer(forKey: Key.hotkeyCode.rawValue); return v == 0 ? 8 : v }() // 8 = 'C'
        hotkeyModifiers    = { 
            let v = d.object(forKey: Key.hotkeyModifiers.rawValue) as? UInt64
            return v ?? (CGEventFlags.maskCommand.rawValue | CGEventFlags.maskShift.rawValue)
        }()
        
        appearance         = d.string(forKey: Key.appearance.rawValue) ?? "System"
        
        showAppIcons       = d.object(forKey: Key.showAppIcons.rawValue) == nil
                               ? true
                               : d.bool(forKey: Key.showAppIcons.rawValue)
                               
        pasteAutomatically = d.object(forKey: Key.pasteAutomatically.rawValue) == nil
                               ? true
                               : d.bool(forKey: Key.pasteAutomatically.rawValue)
    }

    // MARK: - Private

    private func save<T>(_ key: Key, _ value: T) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    private func applyLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("[ClipperPreferences] Launch-at-login error: \(error)")
            }
        }
    }
}
