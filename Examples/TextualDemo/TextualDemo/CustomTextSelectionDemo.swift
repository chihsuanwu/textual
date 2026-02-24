import SwiftUI
import Textual

/// Example demonstrating custom text selection menu actions.
struct CustomTextSelectionDemo: View {
  @State private var showAlert = false
  @State private var alertMessage = ""
  @State private var isTextSelected = false

  private let markdown = """
    # Custom Text Selection Demo

    Select any text below to see custom actions in the context menu.

    ## Try It Out

    This is a **sample paragraph** with some text you can select. Try selecting different portions
    and see the custom actions appear in the menu.

    You can:
    - Translate the selected text
    - Search the web for it
    - Count words
    - Convert to uppercase

    Select a URL like https://example.com to see URL-specific actions.

    Or select an email like user@example.com for email actions.
    """

  var body: some View {
    ScrollView {
      StructuredText(markdown: markdown)
        .textual.textSelection(.enabled)
        .textual.textSelectionState($isTextSelected)
        .textual.textSelectionActions(customActions)
        .padding()
    }
    .overlay(alignment: .bottom) {
      Button("Clear Selection") {
        isTextSelected = false
      }
      .disabled(!isTextSelected)
    }
  }

  private var customActions: [TextSelectionAction] {
    [
      // Translate action - always available
      TextSelectionAction(
        id: "translate",
        title: "Translate",
        systemImage: "translate"
      ) { selectedText in
        alertMessage = "Translating: \(selectedText)"
        showAlert = true
      },

      // Web search - available for short text
      TextSelectionAction(
        id: "search",
        title: "Search Web",
        systemImage: "magnifyingglass",
        validator: { $0.count > 0 && $0.count < 100 }
      ) { selectedText in
        if let encoded = selectedText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
          #if canImport(AppKit)
          NSWorkspace.shared.open(url)
          #elseif canImport(UIKit)
          UIApplication.shared.open(url)
          #endif
        }
      },

      // Word count
      TextSelectionAction(
        id: "wordCount",
        title: "Count Words",
        systemImage: "number"
      ) { selectedText in
        let words = selectedText.components(separatedBy: .whitespacesAndNewlines)
          .filter { !$0.isEmpty }
        alertMessage = "Word count: \(words.count)"
        showAlert = true
      },

      // Uppercase conversion
      TextSelectionAction(
        id: "uppercase",
        title: "Convert to Uppercase",
        systemImage: "textformat.size"
      ) { selectedText in
        alertMessage = selectedText.uppercased()
        showAlert = true
      },

      // Open URL - only for valid URLs
      TextSelectionAction(
        id: "openURL",
        title: "Open URL",
        systemImage: "link",
        validator: { text in
          URL(string: text) != nil && (text.hasPrefix("http://") || text.hasPrefix("https://"))
        }
      ) { selectedText in
        if let url = URL(string: selectedText) {
          #if canImport(AppKit)
          NSWorkspace.shared.open(url)
          #elseif canImport(UIKit)
          UIApplication.shared.open(url)
          #endif
        }
      },

      // Email action - only for email-like text
      TextSelectionAction(
        id: "email",
        title: "Compose Email",
        systemImage: "envelope",
        validator: { text in
          text.contains("@") && text.contains(".")
        }
      ) { selectedText in
        if let url = URL(string: "mailto:\(selectedText)") {
          #if canImport(AppKit)
          NSWorkspace.shared.open(url)
          #elseif canImport(UIKit)
          UIApplication.shared.open(url)
          #endif
        }
      },

      // Highlight - available for text longer than 10 characters
      TextSelectionAction(
        id: "highlight",
        title: "Highlight",
        systemImage: "highlighter",
        validator: { $0.count > 10 }
      ) { selectedText in
        alertMessage = "Highlighted: \(selectedText)"
        showAlert = true
      }
    ]
  }
}

/// Example showing how to use TextSelectionMenuConfiguration for advanced control.
struct AdvancedTextSelectionDemo: View {
  private let content = """
    # Advanced Configuration

    This example shows how to position custom actions **before** standard actions.
    """

  var body: some View {
    StructuredText(markdown: content)
      .textual.textSelection(.enabled)
      .textual.textSelectionMenu(
        TextSelectionMenuConfiguration(
          customActions: [
            TextSelectionAction(
              id: "priority",
              title: "Priority Action",
              systemImage: "star.fill"
            ) { text in
              print("Priority action: \(text)")
            }
          ],
          position: .before  // Show before Copy and Share
        )
      )
      .padding()
  }
}

/// Example for integrating with app-specific features.
struct IntegratedTextSelectionDemo: View {
  @State private var highlights: Set<String> = []
  @State private var notes: [String] = []

  private let markdown = """
    # Integration Example

    Select text to add it to highlights or notes.
    This demonstrates how to integrate text selection with your app's features.
    """

  var body: some View {
    VStack(spacing: 20) {
      StructuredText(markdown: markdown)
        .textual.textSelection(.enabled)
        .textual.textSelectionActions([
          TextSelectionAction(
            id: "addHighlight",
            title: "Add to Highlights",
            systemImage: "bookmark.fill"
          ) { text in
            highlights.insert(text)
          },

          TextSelectionAction(
            id: "addNote",
            title: "Add to Notes",
            systemImage: "note.text"
          ) { text in
            notes.append(text)
          }
        ])
        .padding()

      Divider()

      // Display highlights
      VStack(alignment: .leading, spacing: 10) {
        Text("Highlights (\(highlights.count))")
          .font(.headline)

        ForEach(Array(highlights), id: \.self) { highlight in
          Text("• \(highlight)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()

      // Display notes
      VStack(alignment: .leading, spacing: 10) {
        Text("Notes (\(notes.count))")
          .font(.headline)

        ForEach(notes.indices, id: \.self) { index in
          Text("\(index + 1). \(notes[index])")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
  }
}

#Preview("Custom Actions") {
  CustomTextSelectionDemo()
}

#Preview("Advanced Config") {
  AdvancedTextSelectionDemo()
}

#Preview("Integration") {
  IntegratedTextSelectionDemo()
}

