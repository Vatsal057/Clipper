import SwiftUI
import AppKit

// MARK: - ClipItemRow

/// A single clipboard history row. Shows app icon, preview, timestamp, pin button.
struct ClipItemRow: View {

    let item: ClipboardItem
    let index: Int
    let isSelected:  Bool
    let onTap:       () -> Void
    let onDelete:    () -> Void
    let onTogglePin: () -> Void

    @ObservedObject private var prefs = ClipperPreferences.shared
    @State private var hovered = false

    // MARK: Design tokens
    private let accentColor   = Color(hue: 0.13, saturation: 0.85, brightness: 0.95)  // warm amber
    private let rowHeight: CGFloat = 60

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // App icon
                if prefs.showAppIcons {
                    appIconView
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                }

                // Content preview
                VStack(alignment: .leading, spacing: 4) {
                    previewText
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(isSelected ? .white : .primary)

                    HStack(spacing: 6) {
                        if let name = item.appName {
                            Text(name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(isSelected ? .white.opacity(0.9) : .tertiary)
                        }
                        Text("·")
                            .font(.system(size: 11))
                            .foregroundStyle(isSelected ? .white.opacity(0.6) : .quaternary)
                        Text(relativeTime)
                            .font(.system(size: 11))
                            .foregroundStyle(isSelected ? .white.opacity(0.9) : .tertiary)
                        // Character count for text items
                        if case .text(let s) = item.content, s.count > 0 {
                            Text("·")
                                .font(.system(size: 11))
                                .foregroundStyle(isSelected ? .white.opacity(0.6) : .quaternary)
                            Text("\(s.count) chars")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(isSelected ? .white.opacity(0.6) : .quaternary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Actions & Shortcuts
                HStack(spacing: 12) {
                    if hovered || item.pinned {
                        pinButton
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    }
                    if hovered {
                        deleteButton
                            .transition(.opacity.combined(with: .scale(scale: 0.7)))
                    } else if !hovered && !item.pinned {
                        if index < 9 {
                            Text("⌘\(index + 1)")
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundStyle(isSelected ? .white : .tertiary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().strokeBorder(isSelected ? Color.white.opacity(0.3) : Color.primary.opacity(0.1)))
                        } else if isSelected {
                            Image(systemName: "return")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(Capsule().strokeBorder(Color.white.opacity(0.3)))
                        }
                    }
                }
                .animation(.easeOut(duration: 0.12), value: hovered)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
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
        case .image(let data):
            if let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 40)
                    .cornerRadius(4)
            } else {
                Label("Image", systemImage: "photo")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
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
                .foregroundStyle(item.pinned ? (isSelected ? .white : accentColor) : (isSelected ? .white.opacity(0.8) : Color.secondary))
        }
        .buttonStyle(.plain)
        .help(item.pinned ? "Unpin" : "Pin to top")
    }

    private var deleteButton: some View {
        Button(action: onDelete) {
            Image(systemName: "trash")
                .font(.system(size: 11))
                .foregroundStyle(isSelected ? .white.opacity(0.8) : .tertiary)
        }
        .buttonStyle(.plain)
        .help("Delete")
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.accentColor)
        } else if hovered {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.05), lineWidth: 1)
                )
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
