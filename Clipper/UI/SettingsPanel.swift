import SwiftUI
import AppKit

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

                    settingsGroup("History") {
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
        .frame(width: 300, height: 340)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
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
}
