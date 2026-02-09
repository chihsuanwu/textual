#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(AppKit)
  import SwiftUI

  // MARK: - Overview
  //
  // `AppKitTextInteractionOverlay` bridges the shared `TextSelectionModel` into an `NSView`.
  //
  // The overlay reads exclusion rectangles from the `overflowFrames` environment value and passes
  // them to `NSTextInteractionView` for hit-testing. This allows embedded scrollable regions (like
  // code blocks) to receive touch events while the parent handles text selection. The view also
  // manages selection gestures, keyboard-driven updates, and context menus while SwiftUI renders
  // the text.

  struct AppKitTextInteractionOverlay: NSViewRepresentable {
    private let model: TextSelectionModel

    init(model: TextSelectionModel) {
      self.model = model
    }

    func makeNSView(context: Context) -> NSTextInteractionView {
      NSTextInteractionView(
        model: model,
        exclusionRects: context.environment.overflowFrames,
        openURL: context.environment.openURL,
        menuConfiguration: context.environment.textSelectionMenuConfiguration
      )
    }

    func updateNSView(_ nsView: NSTextInteractionView, context: Context) {
      nsView.model = model
      nsView.exclusionRects = context.environment.overflowFrames
      nsView.openURL = context.environment.openURL
      nsView.menuConfiguration = context.environment.textSelectionMenuConfiguration
    }
  }
#endif
