import SwiftUI
import AppKit
import ServiceManagement

// MARK: - SettingsPanel
// A compact settings sheet shown from the popover footer.

struct SettingsPanel: View {

    @ObservedObject private var prefs = ClipperPreferences.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 2) {
                    settingsGroup("General") {
                        toggle("Launch at login", isOn: $prefs.launchAtLogin,
                               icon: "power", note: nil)
                        toggle("Sound on copy", isOn: $prefs.soundOnCopy,
                               icon: "speaker.wave.2", note: nil)
                    }
                    
                    settingsGroup("Shortcuts") {
                        HotkeyRecorder(
                            keyCode: $prefs.hotkeyCode,
                            modifiers: $prefs.hotkeyModifiers
                        )
                    }
                    
                    settingsGroup("Appearance") {
                        pickerRow("Theme", selection: $prefs.appearance, options: ["System", "Light", "Dark"], icon: "paintpalette")
                        toggle("Show app icons", isOn: $prefs.showAppIcons, icon: "app.badge", note: nil)
                    }

                    settingsGroup("Behavior") {
                        toggle("Paste automatically", isOn: $prefs.pasteAutomatically, icon: "doc.on.clipboard", note: "When disabled, items are just copied.")
                        stepperRow("Max items",
                                   value: $prefs.maxHistoryCount,
                                   range: 20...500, step: 20,
                                   icon: "clock.arrow.circlepath")
                    }

                    settingsGroup("About") {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundStyle(.secondary)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Clipper")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Version \(appVersion)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            Link("GitHub", destination: URL(string: "https://github.com/Vatsal057/Clipper")!)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }

                    settingsGroup("App") {
                        Button(action: {
                            NSApplication.shared.terminate(nil)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "power")
                                    .foregroundStyle(.red)
                                    .frame(width: 20)
                                Text("Quit Clipper")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300, height: 480)
        .background(
            VisualEffectView(material: .menu, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "2.0"
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.quaternary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)
            content()
        }
    }

    private func toggle(_ label: String, isOn: Binding<Bool>, icon: String, note: String?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 12))
                if let note {
                    Text(note).font(.system(size: 10)).foregroundStyle(.tertiary)
                }
            }
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().toggleStyle(.switch).scaleEffect(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func stepperRow(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label).font(.system(size: 12))
            Spacer()
            Text("\(value.wrappedValue)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(minWidth: 30)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
                .scaleEffect(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
    
    private func pickerRow(_ label: String, selection: Binding<String>, options: [String], icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text(label).font(.system(size: 12))
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.self) { opt in
                    Text(opt).tag(opt)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 100)
            .scaleEffect(0.9)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - HotkeyRecorder

struct HotkeyRecorder: View {
    @Binding var keyCode: Int
    @Binding var modifiers: UInt64
    @State private var isRecording = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "keyboard")
                .foregroundStyle(.secondary)
                .frame(width: 20)
            Text("Global hotkey").font(.system(size: 12))
            Spacer()
            Button(action: { isRecording.toggle() }) {
                Text(isRecording ? "Recording..." : formatHotkey(keyCode: keyCode, modifiers: modifiers))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(isRecording ? Color(nsColor: .controlAccentColor) : .primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
                    .overlay(
                        Capsule().strokeBorder(isRecording ? Color(nsColor: .controlAccentColor) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(EventCatcherView(isRecording: $isRecording, keyCode: $keyCode, modifiers: $modifiers))
    }
    
    private func formatHotkey(keyCode: Int, modifiers: UInt64) -> String {
        var str = ""
        let flags = CGEventFlags(rawValue: modifiers)
        if flags.contains(.maskControl) { str += "⌃" }
        if flags.contains(.maskAlternate) { str += "⌥" }
        if flags.contains(.maskShift) { str += "⇧" }
        if flags.contains(.maskCommand) { str += "⌘" }
        
        let map: [Int: String] = [
            0:"A", 1:"S", 2:"D", 3:"F", 4:"H", 5:"G", 6:"Z", 7:"X", 8:"C", 9:"V", 11:"B", 12:"Q", 13:"W", 14:"E", 15:"R", 16:"Y", 17:"T", 31:"O", 32:"U", 34:"I", 35:"P", 37:"L", 38:"J", 40:"K", 45:"N", 46:"M",
            18:"1", 19:"2", 20:"3", 21:"4", 23:"5", 22:"6", 26:"7", 28:"8", 25:"9", 29:"0", 53:"Esc", 49:"Space"
        ]
        
        if let keyStr = map[keyCode] {
            str += keyStr
        } else {
            str += String(format: "%02X", keyCode)
        }
        return str
    }
}

struct EventCatcherView: NSViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var keyCode: Int
    @Binding var modifiers: UInt64
    
    func makeNSView(context: Context) -> EventCatcherNSView {
        let view = EventCatcherNSView()
        view.onEvent = { code, flags in
            self.keyCode = code
            self.modifiers = flags
            self.isRecording = false
        }
        return view
    }
    
    func updateNSView(_ nsView: EventCatcherNSView, context: Context) {
        nsView.isRecording = isRecording
        if isRecording {
            DispatchQueue.main.async {
                nsView.window?.makeFirstResponder(nsView)
            }
        }
    }
}

class EventCatcherNSView: NSView {
    var isRecording = false
    var onEvent: ((Int, UInt64) -> Void)?
    
    override var acceptsFirstResponder: Bool { true }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if isRecording {
            handleEvent(event)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
    
    override func keyDown(with event: NSEvent) {
        if isRecording {
            handleEvent(event)
        } else {
            super.keyDown(with: event)
        }
    }
    
    private func handleEvent(_ event: NSEvent) {
        let code = Int(event.keyCode)
        let modifierFlags = event.modifierFlags.intersection([.command, .shift, .option, .control])
        
        var cgFlags: CGEventFlags = []
        if modifierFlags.contains(.command) { cgFlags.insert(.maskCommand) }
        if modifierFlags.contains(.shift) { cgFlags.insert(.maskShift) }
        if modifierFlags.contains(.option) { cgFlags.insert(.maskAlternate) }
        if modifierFlags.contains(.control) { cgFlags.insert(.maskControl) }
        
        onEvent?(code, cgFlags.rawValue)
    }
}

