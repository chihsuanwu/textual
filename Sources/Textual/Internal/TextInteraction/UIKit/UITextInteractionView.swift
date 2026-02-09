#if TEXTUAL_ENABLE_TEXT_SELECTION && canImport(UIKit)
  import SwiftUI
  import os
  import UniformTypeIdentifiers

  // MARK: - Overview
  //
  // `UITextInteractionView` implements selection and link interaction on iOS-family platforms.
  //
  // The view sits in an overlay above one or more rendered `Text` fragments. It uses
  // `TextSelectionModel` to translate touch locations into URLs and selection ranges, and it
  // respects `exclusionRects` so embedded scrollable regions can continue to handle gestures.
  // Selection UI is provided by `UITextInteraction` configured for non-editable content.

  final class UITextInteractionView: UIView {
    override var canBecomeFirstResponder: Bool {
      true
    }

    var model: TextSelectionModel
    var exclusionRects: [CGRect]
    var openURL: OpenURLAction
    var menuConfiguration: TextSelectionMenuConfiguration {
      didSet {
        // Re-setup edit menu interaction when configuration changes
        if #available(iOS 16.0, *) {
          setupEditMenuInteractionIfNeeded()
        }
      }
    }

    weak var inputDelegate: (any UITextInputDelegate)?

    let logger = Logger(category: .textInteraction)

    private(set) lazy var _tokenizer = UITextInputStringTokenizer(textInput: self)
    private let selectionInteraction: UITextInteraction

    private var editMenuInteraction: UIEditMenuInteraction?
    private var isEditMenuVisible = false

    init(
      model: TextSelectionModel,
      exclusionRects: [CGRect],
      openURL: OpenURLAction,
      menuConfiguration: TextSelectionMenuConfiguration
    ) {
      self.model = model
      self.exclusionRects = exclusionRects
      self.openURL = openURL
      self.menuConfiguration = menuConfiguration
      self.selectionInteraction = UITextInteraction(for: .nonEditable)

      super.init(frame: .zero)
      self.backgroundColor = .clear

      setUp()
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
      for exclusionRect in exclusionRects {
        if exclusionRect.contains(point) {
          return false
        }
      }
      return super.point(inside: point, with: event)
    }

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
      guard let selectedRange = model.selectedRange, !selectedRange.isCollapsed else {
        return false
      }

      // If we have custom actions configured, disable system menu items
      // so our UIEditMenuInteraction can handle everything
      if #available(iOS 16.0, *), !menuConfiguration.customActions.isEmpty {
        return false
      }

      switch action {
      case #selector(copy(_:)), #selector(share(_:)):
        return true
      default:
        return false
      }
    }

    override func copy(_ sender: Any?) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      let attributedText = model.attributedText(in: selectedRange)
      let formatter = Formatter(attributedText)

      UIPasteboard.general.setItems(
        [
          [
            UTType.plainText.identifier: formatter.plainText(),
            UTType.html.identifier: formatter.html(),
          ]
        ]
      )
    }

    private func setUp() {
      model.selectionWillChange = { [weak self] in
        guard let self else { return }
        self.inputDelegate?.selectionWillChange(self)
      }
      model.selectionDidChange = { [weak self] in
        guard let self else { return }
        self.inputDelegate?.selectionDidChange(self)

        // Present custom edit menu when selection changes (iOS 16+)
        // Only if we have custom actions configured and menu isn't already showing
        if #available(iOS 16.0, *),
           !self.menuConfiguration.customActions.isEmpty,
           !self.isEditMenuVisible {
          self.scheduleCustomEditMenu()
        }
      }

      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
      addGestureRecognizer(tapGesture)

      selectionInteraction.textInput = self
      selectionInteraction.delegate = self

      for gesture in selectionInteraction.gesturesForFailureRequirements {
        tapGesture.require(toFail: gesture)
      }

      addInteraction(selectionInteraction)

      // Setup edit menu interaction if needed
      if #available(iOS 16.0, *) {
        setupEditMenuInteractionIfNeeded()
      }
    }

    @available(iOS 16.0, *)
    private func setupEditMenuInteractionIfNeeded() {
      // Only setup if we have custom actions and don't already have an interaction
      guard !menuConfiguration.customActions.isEmpty else {
        // Remove existing interaction if no custom actions
        if let existingInteraction = editMenuInteraction {
          removeInteraction(existingInteraction)
          editMenuInteraction = nil
        }
        return
      }

      // Already have an interaction, no need to recreate
      if editMenuInteraction != nil {
        return
      }

      // Create and add new interaction
      let interaction = UIEditMenuInteraction(delegate: self)
      self.editMenuInteraction = interaction
      addInteraction(interaction)
    }

    private var pendingMenuWorkItem: DispatchWorkItem?

    @available(iOS 16.0, *)
    private func scheduleCustomEditMenu() {
      // Don't do anything if menu is already visible
      if isEditMenuVisible {
        return
      }

      // Cancel any pending menu presentation
      pendingMenuWorkItem?.cancel()

      guard let selectedRange = model.selectedRange,
            !selectedRange.isCollapsed else {
        return
      }

      // Schedule menu presentation with a small delay
      // This allows the system menu to be dismissed first
      let workItem = DispatchWorkItem { [weak self] in
        guard let self else { return }
        // Double-check menu isn't visible before presenting
        if !self.isEditMenuVisible {
          self.presentCustomEditMenu()
        }
      }
      pendingMenuWorkItem = workItem
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    @available(iOS 16.0, *)
    func presentCustomEditMenu() {
      guard let editMenuInteraction = editMenuInteraction,
            let range = model.selectedRange,
            !range.isCollapsed,
            !isEditMenuVisible else { return }

      let rect = model.selectionRects(for: range).first?.rect ?? .zero
      let config = UIEditMenuConfiguration(
        identifier: nil,
        sourcePoint: CGPoint(x: rect.midX, y: rect.minY)
      )
      editMenuInteraction.presentEditMenu(with: config)
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
      let location = gesture.location(in: self)
      guard let url = model.url(for: location) else {
        return
      }
      openURL(url)
    }

    @objc private func share(_ sender: Any?) {
      guard let selectedRange = model.selectedRange else {
        return
      }

      let attributedText = model.attributedText(in: selectedRange)
      let itemSource = TextActivityItemSource(attributedString: attributedText)

      let activityViewController = UIActivityViewController(
        activityItems: [itemSource],
        applicationActivities: nil
      )

      if let popover = activityViewController.popoverPresentationController {
        let rect =
          model.selectionRects(for: selectedRange)
          .last?.rect.integral ?? .zero
        popover.sourceView = self
        popover.sourceRect = rect
      }

      if let windowScene = window?.windowScene,
        let viewController = windowScene.windows.first?.rootViewController
      {
        viewController.present(activityViewController, animated: true)
      }
    }
  }

  // MARK: - UITextInteractionDelegate

  extension UITextInteractionView: UITextInteractionDelegate {
    func interactionShouldBegin(_ interaction: UITextInteraction, at point: CGPoint) -> Bool {
      // Don't allow text interaction to interfere when our menu is visible
      if #available(iOS 16.0, *), isEditMenuVisible {
        logger.debug("interactionShouldBegin(at: \(point.logDescription)) -> false (menu visible)")
        return false
      }
      logger.debug("interactionShouldBegin(at: \(point.logDescription)) -> true")
      return true
    }

    func interactionWillBegin(_ interaction: UITextInteraction) {
      logger.debug("interactionWillBegin")
      _ = self.becomeFirstResponder()
    }

    func interactionDidEnd(_ interaction: UITextInteraction) {
      logger.debug("interactionDidEnd")
    }
  }

  // MARK: - UIEditMenuInteractionDelegate (iOS 16+)

  @available(iOS 16.0, *)
extension UITextInteractionView: @MainActor UIEditMenuInteractionDelegate {
    func editMenuInteraction(
      _ interaction: UIEditMenuInteraction,
      menuFor configuration: UIEditMenuConfiguration,
      suggestedActions: [UIMenuElement]
    ) -> UIMenu? {
      guard let selectedRange = model.selectedRange, !selectedRange.isCollapsed else {
        return nil
      }

      let selectedText = model.attributedText(in: selectedRange).string

      // Build standard actions
      let copyAction = UIAction(
        title: NSLocalizedString("Copy", comment: ""),
        image: UIImage(systemName: "doc.on.doc")
      ) { [weak self] _ in
        self?.copy(nil)
      }

      let shareAction = UIAction(
        title: NSLocalizedString("Share…", comment: ""),
        image: UIImage(systemName: "square.and.arrow.up")
      ) { [weak self] _ in
        self?.share(nil)
      }

      let standardActions: [UIMenuElement] = [copyAction, shareAction]

      // Build custom actions
      var customMenuActions: [UIAction] = []
      for action in menuConfiguration.customActions {
        guard action.validator(selectedText) else {
          continue
        }

        let handler = action.handler
        let uiAction = UIAction(
          title: action.title,
          image: action.systemImage.flatMap { UIImage(systemName: $0) }
        ) { [weak self] _ in
          guard let self,
                let range = self.model.selectedRange else { return }
          let text = self.model.attributedText(in: range).string
          handler(text)
        }
        customMenuActions.append(uiAction)
      }

      // If no custom actions, just return standard actions
      guard !customMenuActions.isEmpty else {
        return UIMenu(children: standardActions)
      }

      // Combine actions based on position
      let allActions: [UIMenuElement]
      switch menuConfiguration.position {
      case .before:
        allActions = customMenuActions + standardActions
      case .after:
        allActions = standardActions + customMenuActions
      }

      return UIMenu(children: allActions)
    }

    func editMenuInteraction(
      _ interaction: UIEditMenuInteraction,
      targetRectFor configuration: UIEditMenuConfiguration
    ) -> CGRect {
      guard let selectedRange = model.selectedRange else {
        return .zero
      }
      return model.selectionRects(for: selectedRange).first?.rect ?? .zero
    }

    func editMenuInteraction(
      _ interaction: UIEditMenuInteraction,
      willPresentMenuFor configuration: UIEditMenuConfiguration,
      animator: any UIEditMenuInteractionAnimating
    ) {
      isEditMenuVisible = true
    }

    func editMenuInteraction(
      _ interaction: UIEditMenuInteraction,
      willDismissMenuFor configuration: UIEditMenuConfiguration,
      animator: any UIEditMenuInteractionAnimating
    ) {
      animator.addCompletion { [weak self] in
        self?.isEditMenuVisible = false
      }
    }
  }

  extension Logger.Textual.Category {
    fileprivate static let textInteraction = Self(rawValue: "textInteraction")
  }
#endif
