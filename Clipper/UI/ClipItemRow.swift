import SwiftUI
import AppKit

// MARK: - ClipItemRow

/// A single clipboard history row. Shows app icon, preview, timestamp, pin button.
struct ClipItemRow: View {

    let item: ClipboardItem
    let onTap:       () -> Void
    let onDelete:    () -> Void
    let onTogglePin: () -> Void

    @State private var hovered = false

    // MARK: Design tokens
    private let accentColor   = Color(hue: 0.13, saturation: 0.85, brightness: 0.95)  // warm amber
    private let rowHeight: CGFloat = 52

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // App icon
                appIconView
                    .frame(width: 20, height: 20)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                // Content preview
                VStack(alignment: .leading, spacing: 2) {
                    previewText
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(hovered ? Color.primary : Color.primary.opacity(0.9))

                    HStack(spacing: 4) {
                        if let name = item.appName {
                            Text(name)
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        Text("·")
                            .font(.system(size: 10))
                            .foregroundStyle(.quaternary)
                        Text(relativeTime)
                            .font(.system(size: 10))
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Actions (visible on hover or when pinned)
                HStack(spacing: 6) {
                    if hovered || item.pinned {
                        pinButton
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    }
                    if hovered {
                        deleteButton
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    }
                }
                .animation(.easeOut(duration: 0.12), value: hovered)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: rowHeight)
            .background(rowBackground)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private var previewText: some View {
        switch item.content {
        case .text(let s):
            Text(s)
        case .image:
            Label("Image", systemImage: "photo")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var appIconView: some View {
        if let data = item.appIconData, let img = NSImage(data: data) {
            Image(nsImage: img)
                .resizable()
                .interpolation(.high)
        } else {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
    }

    private var pinButton: some View {
        Button(action: onTogglePin) {
            Image(systemName: item.pinned ? "pin.fill" : "pin")
                .font(.system(size: 11))
                .foregroundStyle(item.pinned ? accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .help(item.pinned ? "Unpin" : "Pin to top")
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .buttonStyle(.plain)
        .help("Delete")
    }

    @ViewBuilder
    private var rowBackground: some View {
        if hovered {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlAccentColor).opacity(0.15))
        } else {
            Color.clear
        }
    }

    // MARK: - Helpers

    private var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: item.date, relativeTo: Date())
    }
}
