import SwiftUI

/// Represents a custom action that can be added to the text selection menu.
///
/// Use `TextSelectionAction` to define custom menu items that appear when users select text.
///
/// Example:
/// ```swift
/// let translateAction = TextSelectionAction(
///   id: "translate",
///   title: "Translate",
///   systemImage: "translate"
/// ) { selectedText in
///   print("Translating: \(selectedText)")
/// }
/// ```
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct TextSelectionAction: Identifiable, Sendable {
  /// A unique identifier for this action.
  public let id: String

  /// The title displayed in the menu.
  public let title: String

  /// An optional SF Symbol name to display alongside the title (macOS only).
  public let systemImage: String?

  /// A closure that determines whether this action should be enabled for the given text.
  ///
  /// Return `true` to enable the action, or `false` to disable or hide it.
  public let validator: @Sendable (String) -> Bool

  /// The action to perform when the menu item is selected.
  ///
  /// The closure receives the selected text as a parameter.
  public let handler: @Sendable (String) -> Void

  /// Creates a new text selection action.
  ///
  /// - Parameters:
  ///   - id: A unique identifier for this action.
  ///   - title: The title displayed in the menu.
  ///   - systemImage: An optional SF Symbol name (macOS only).
  ///   - validator: A closure that determines if this action is available for the selected text.
  ///                Defaults to always returning `true`.
  ///   - handler: The action to perform when selected.
  public init(
    id: String,
    title: String,
    systemImage: String? = nil,
    validator: @escaping @Sendable (String) -> Bool = { _ in true },
    handler: @escaping @Sendable (String) -> Void
  ) {
    self.id = id
    self.title = title
    self.systemImage = systemImage
    self.validator = validator
    self.handler = handler
  }
}

/// Configuration for customizing the text selection menu.
///
/// Use this type to add custom actions to the text selection menu that appears
/// when users select text in `InlineText` or `StructuredText`.
///
/// Example:
/// ```swift
/// StructuredText(markdown: content)
///   .textual.textSelection(.enabled)
///   .textual.textSelectionActions([
///     TextSelectionAction(
///       id: "highlight",
///       title: "Highlight",
///       systemImage: "highlighter"
///     ) { selectedText in
///       // Handle highlight action
///     },
///     TextSelectionAction(
///       id: "search",
///       title: "Search Web",
///       validator: { !$0.isEmpty && $0.count < 100 }
///     ) { selectedText in
///       // Open web search
///     }
///   ])
/// ```
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public struct TextSelectionMenuConfiguration: Equatable, Sendable {
  /// Custom actions to display in the text selection menu.
  public var customActions: [TextSelectionAction]

  /// Whether to show the custom actions before or after the standard actions (Copy, Share).
  public var position: Position

  /// The position of custom actions relative to standard actions.
  public enum Position: Sendable {
    /// Display custom actions before standard actions.
    case before
    /// Display custom actions after standard actions.
    case after
  }

  /// Creates a new text selection menu configuration.
  ///
  /// - Parameters:
  ///   - customActions: An array of custom actions to add to the menu.
  ///   - position: Where to place the custom actions relative to standard actions.
  public init(
    customActions: [TextSelectionAction] = [],
    position: Position = .after
  ) {
    self.customActions = customActions
    self.position = position
  }

  public static func == (lhs: TextSelectionMenuConfiguration, rhs: TextSelectionMenuConfiguration) -> Bool {
    lhs.customActions.map(\.id) == rhs.customActions.map(\.id) &&
    lhs.position == rhs.position
  }
}

#if TEXTUAL_ENABLE_TEXT_SELECTION
  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @Entry var textSelectionMenuConfiguration = TextSelectionMenuConfiguration()
  }
#endif

