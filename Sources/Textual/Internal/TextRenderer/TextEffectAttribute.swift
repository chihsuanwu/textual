import SwiftUI

// MARK: - Overview
//
// `TextEffectAttribute` marks text runs that should receive custom drawing effects.
//
// When a `TextRunEffect` is applied through the `TextProperty` system, it is stored
// in the `AttributeContainer` as a `TextEffectAttribute`. The `TextualTextRenderer`
// reads this attribute to determine which runs need custom drawing.

struct TextEffectAttribute: TextAttribute {
  let effect: AnyTextRunEffect
}

extension Text.Layout.Run {
  /// Returns the text run effect applied to this run, if any.
  var textEffect: AnyTextRunEffect? {
    self[TextEffectAttribute.self]?.effect
  }
}

/// The attribute key for storing text effects in `AttributeContainer`.
enum TextEffectAttributeKey: AttributedStringKey {
  typealias Value = AnyTextRunEffect

  static let name = "Textual.TextEffect"
}

/// An attribute scope for text effect attributes.
extension AttributeScopes {
  struct TextualEffectAttributes: AttributeScope {
    let textualEffect: TextEffectAttributeKey
  }

  var textualEffect: TextualEffectAttributes.Type { TextualEffectAttributes.self }
}

extension AttributeContainer {
  var textualEffect: AnyTextRunEffect? {
    get { self[TextEffectAttributeKey.self] }
    set { self[TextEffectAttributeKey.self] = newValue }
  }
}

extension AttributedString.Runs.Run {
  /// Returns the text run effect applied to this run, if any.
  var textualEffect: AnyTextRunEffect? {
    self[TextEffectAttributeKey.self]
  }
}
