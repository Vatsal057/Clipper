import SwiftUI

// MARK: - ClipperPanel

/// Root SwiftUI view hosted inside the NSPopover / cursor NSPanel.
/// 340×500pt, dark popover material, search + scrollable history + footer.
struct ClipperPanel: View {

    // MARK: Dependencies
    @State private var store: ClipboardStore  // @Observable — no @ObservedObject needed
    let onPaste: (ClipboardItem) -> Void
    let onClose: () -> Void

    // MARK: Local state
    @State private var searchText        = ""
    @State private var showClearConfirm  = false
    @State private var showSettings      = false
    @State private var selectedIndex: Int = 0
    @State private var eventMonitor: Any?

    // MARK: Design
    private let panelWidth:  CGFloat = 340
    private let panelHeight: CGFloat = 500

    // MARK: Init
    init(store: ClipboardStore, onPaste: @escaping (ClipboardItem) -> Void, onClose: @escaping () -> Void) {
        self._store  = State(initialValue: store)
        self.onPaste = onPaste
        self.onClose = onClose
    }

    // MARK: - Filtered items

    private var filtered: [ClipboardItem] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return store.items }
        return store.items.filter { item in
            switch item.content {
            case .text(let s): return s.lowercased().contains(q)
            case .image:       return "image".contains(q)
            }
        }
    }
    
    private func clampSelection() {
        if filtered.isEmpty {
            selectedIndex = 0
        } else if selectedIndex >= filtered.count {
            selectedIndex = filtered.count - 1
        } else if selectedIndex < 0 {
            selectedIndex = 0
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider().opacity(0.3)

            // List or empty state
            if filtered.isEmpty {
                emptyState
            } else {
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 0) {
                            ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                                ClipItemRow(
                                    item: item,
                                    isSelected:  index == selectedIndex,
                                    onTap:       { onPaste(item) },
                                    onDelete:    { store.delete(id: item.id) },
                                    onTogglePin: { store.togglePin(id: item.id) }
                                )
                                .id(item.id)

                                if item.id != filtered.last?.id {
                                    Divider()
                                        .padding(.horizontal, 12)
                                        .opacity(0.2)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        .onChange(of: selectedIndex) { _, newIndex in
                            guard newIndex >= 0, newIndex < filtered.count else { return }
                            withAnimation(.easeInOut(duration: 0.1)) {
                                proxy.scrollTo(filtered[newIndex].id, anchor: .center)
                            }
                        }
                    }
                }
            }

            Divider().opacity(0.3)

            // Footer
            footer
        }
        .frame(width: panelWidth, height: panelHeight)
        .background(
            VisualEffectView(material: .popover, blendingMode: .behindWindow)
                .ignoresSafeArea()
        )
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showSettings) {
            SettingsPanel()
        }
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0 // Reset selection on search
        }
        .onAppear {
            setupEventMonitor()
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Quick Paste: ⌘1 to ⌘9
            if event.modifierFlags.contains(.command) && !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.option) {
                switch event.keyCode {
                case 18: if 0 < filtered.count { onPaste(filtered[0]); return nil }
                case 19: if 1 < filtered.count { onPaste(filtered[1]); return nil }
                case 20: if 2 < filtered.count { onPaste(filtered[2]); return nil }
                case 21: if 3 < filtered.count { onPaste(filtered[3]); return nil }
                case 23: if 4 < filtered.count { onPaste(filtered[4]); return nil }
                case 22: if 5 < filtered.count { onPaste(filtered[5]); return nil }
                case 26: if 6 < filtered.count { onPaste(filtered[6]); return nil }
                case 28: if 7 < filtered.count { onPaste(filtered[7]); return nil }
                case 25: if 8 < filtered.count { onPaste(filtered[8]); return nil }
                default: break
                }
            }

            switch event.keyCode {
            case 53: // Esc
                onClose()
                return nil
            case 125: // Down arrow
                if selectedIndex < filtered.count - 1 {
                    selectedIndex += 1
                }
                return nil // Consume event
            case 126: // Up arrow
                if selectedIndex > 0 {
                    selectedIndex -= 1
                }
                return nil
            case 36, 76: // Return / Enter
                if !filtered.isEmpty, selectedIndex >= 0, selectedIndex < filtered.count {
                    onPaste(filtered[selectedIndex])
                }
                return nil
            default:
                return event
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Clipper")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                // Item count badge
                Text("\(store.items.count)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.quaternary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.primary.opacity(0.06))
                    )

                // Settings gear
                Button { showSettings = true } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .help("Settings")
            }

            SearchBar(text: $searchText)
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: searchText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                .font(.system(size: 32, weight: .ultraLight))
                .foregroundStyle(.quaternary)
            Text(searchText.isEmpty ? "Nothing copied yet" : "No results")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
            if searchText.isEmpty {
                Text("Quick templates are pinned below once you copy something.")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("⌘⇧C")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.quaternary)

            Spacer()

            if !store.items.isEmpty {
                Button("Clear") {
                    showClearConfirm = true
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .buttonStyle(.plain)
                .confirmationDialog(
                    "Clear all unpinned clipboard history?",
                    isPresented: $showClearConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Clear Unpinned", role: .destructive) {
                        store.clearUnpinned()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - VisualEffectView

/// Thin NSVisualEffectView wrapper for SwiftUI.
struct VisualEffectView: NSViewRepresentable {
    let material:     NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material     = material
        v.blendingMode = blendingMode
        v.state        = .active
        return v
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
