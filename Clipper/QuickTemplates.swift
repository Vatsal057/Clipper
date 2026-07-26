import Foundation
import AppKit

// MARK: - QuickTemplates
// Built-in text templates the user can paste in one click.
// These are pre-seeded into the store as permanently pinned items on first launch.

enum QuickTemplates {

    struct Template {
        let label: String
        let content: String
    }

    static let defaults: [Template] = [
        Template(label: "Email sign-off",  content: "Best,\n[Your Name]"),
        Template(label: "Date today",      content: { formattedToday() }()),
        Template(label: "Separator",       content: "---"),
        Template(label: "TODO",            content: "TODO: "),
        Template(label: "Lorem snippet",   content: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."),
    ]

    private static func formattedToday() -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .long
        fmt.timeStyle = .none
        return fmt.string(from: Date())
    }
}
