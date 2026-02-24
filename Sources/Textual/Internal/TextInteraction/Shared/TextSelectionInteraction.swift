import SwiftUI

// MARK: - Overview
//
// `TextSelectionInteraction` manages the text selection model lifecycle for multiple `Text` fragments.
//
// Selection is opt-in through the `textSelection` environment value. When enabled, the modifier
// observes text layout changes via `overlayTextLayoutCollection` and creates or updates a
// `TextSelectionModel`. The model is then passed to the platform-specific implementation
// (`PlatformTextSelectionInteraction`), which presents the appropriate selection UI for macOS
// or iOS. This separation keeps model management in shared code while platform interactions
// remain independent.

struct TextSelectionInteraction: ViewModifier {
  #if TEXTUAL_ENABLE_TEXT_SELECTION
    @Environment(\.textSelection) private var textSelection
    @Environment(\.textSelectionStateBinding) private var selectionStateBinding
    @Environment(TextSelectionCoordinator.self) private var coordinator: TextSelectionCoordinator?

    @State private var model = TextSelectionModel()
  #endif

  func body(content: Content) -> some View {
    #if TEXTUAL_ENABLE_TEXT_SELECTION
      if textSelection.allowsSelection {
        content
          .overlayTextLayoutCollection { layoutCollection in
            Color.clear
              .onChange(of: AnyTextLayoutCollection(layoutCollection), initial: true) {
                model.setCoordinator(coordinator)
                model.setLayoutCollection(layoutCollection)
              }
          }
          .modifier(PlatformTextSelectionInteraction(model: model))
          .modifier(TextSelectionStateSync(model: model, binding: selectionStateBinding))
      } else {
        content
      }
    #else
      content
    #endif
  }
}

// MARK: - TextSelectionStateSync
//
// Synchronizes the `TextSelectionModel.selectedRange` with an external `Binding<Bool>`.
//
// When the model's selection changes, the binding is updated to reflect whether text is selected.
// When the binding is set to `false` externally, the model's selection is cleared.

#if TEXTUAL_ENABLE_TEXT_SELECTION
  private struct TextSelectionStateSync: ViewModifier {
    let model: TextSelectionModel
    let binding: Binding<Bool>?

    func body(content: Content) -> some View {
      if let binding {
        content
          .onChange(of: model.selectedRange != nil) { _, isSelected in
            if binding.wrappedValue != isSelected {
              binding.wrappedValue = isSelected
            }
          }
          .onChange(of: binding.wrappedValue) { _, newValue in
            if !newValue && model.selectedRange != nil {
              model.selectedRange = nil
            }
          }
      } else {
        content
      }
    }
  }
#endif

#if TEXTUAL_ENABLE_TEXT_SELECTION
  extension EnvironmentValues {
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @usableFromInline
    @Entry var textSelection: any TextSelectability.Type = DisabledTextSelectability.self

    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @Entry var textSelectionStateBinding: Binding<Bool>? = nil
  }
#endif
