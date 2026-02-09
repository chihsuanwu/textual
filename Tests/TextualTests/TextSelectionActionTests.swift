import XCTest
@testable import Textual

#if TEXTUAL_ENABLE_TEXT_SELECTION
@available(macOS 12.0, iOS 15.0, *)
final class TextSelectionActionTests: XCTestCase {

    func testTextSelectionActionCreation() {
        let action = TextSelectionAction(
            id: "test",
            title: "Test Action"
        ) { _ in }

        XCTAssertEqual(action.id, "test")
        XCTAssertEqual(action.title, "Test Action")
        XCTAssertNil(action.systemImage)
    }

    func testTextSelectionActionWithImage() {
        let action = TextSelectionAction(
            id: "test",
            title: "Test Action",
            systemImage: "star"
        ) { _ in }

        XCTAssertEqual(action.systemImage, "star")
    }

    func testTextSelectionActionValidator() {
        let action = TextSelectionAction(
            id: "test",
            title: "Test Action",
            validator: { $0.count > 5 }
        ) { _ in }

        XCTAssertTrue(action.validator("Hello World"))
        XCTAssertFalse(action.validator("Hi"))
    }

    func testTextSelectionActionHandler() {
        var handlerCalled = false
        var receivedText = ""

        let action = TextSelectionAction(
            id: "test",
            title: "Test Action"
        ) { text in
            handlerCalled = true
            receivedText = text
        }

        action.handler("Test Text")

        XCTAssertTrue(handlerCalled)
        XCTAssertEqual(receivedText, "Test Text")
    }

    func testMenuConfigurationCreation() {
        let config = TextSelectionMenuConfiguration()

        XCTAssertTrue(config.customActions.isEmpty)
        XCTAssertEqual(config.position, .after)
    }

    func testMenuConfigurationWithActions() {
        let action1 = TextSelectionAction(id: "1", title: "Action 1") { _ in }
        let action2 = TextSelectionAction(id: "2", title: "Action 2") { _ in }

        let config = TextSelectionMenuConfiguration(
            customActions: [action1, action2],
            position: .before
        )

        XCTAssertEqual(config.customActions.count, 2)
        XCTAssertEqual(config.customActions[0].id, "1")
        XCTAssertEqual(config.customActions[1].id, "2")
        XCTAssertEqual(config.position, .before)
    }

    func testMenuConfigurationEquality() {
        let action1 = TextSelectionAction(id: "1", title: "Action 1") { _ in }
        let action2 = TextSelectionAction(id: "2", title: "Action 2") { _ in }

        let config1 = TextSelectionMenuConfiguration(
            customActions: [action1, action2],
            position: .after
        )

        let config2 = TextSelectionMenuConfiguration(
            customActions: [action1, action2],
            position: .after
        )

        let config3 = TextSelectionMenuConfiguration(
            customActions: [action1],
            position: .after
        )

        XCTAssertEqual(config1, config2)
        XCTAssertNotEqual(config1, config3)
    }

    func testDefaultValidator() {
        let action = TextSelectionAction(
            id: "test",
            title: "Test Action"
        ) { _ in }

        // Default validator should always return true
        XCTAssertTrue(action.validator(""))
        XCTAssertTrue(action.validator("Any text"))
        XCTAssertTrue(action.validator("12345"))
    }

    func testConditionalValidators() {
        // URL validator
        let urlAction = TextSelectionAction(
            id: "url",
            title: "Open URL",
            validator: { text in
                URL(string: text) != nil && text.hasPrefix("http")
            }
        ) { _ in }

        XCTAssertTrue(urlAction.validator("https://example.com"))
        XCTAssertFalse(urlAction.validator("not a url"))
        XCTAssertFalse(urlAction.validator("example.com"))

        // Email validator
        let emailAction = TextSelectionAction(
            id: "email",
            title: "Send Email",
            validator: { $0.contains("@") && $0.contains(".") }
        ) { _ in }

        XCTAssertTrue(emailAction.validator("user@example.com"))
        XCTAssertFalse(emailAction.validator("not an email"))

        // Length validator
        let lengthAction = TextSelectionAction(
            id: "short",
            title: "Short Text Only",
            validator: { $0.count > 0 && $0.count < 50 }
        ) { _ in }

        XCTAssertTrue(lengthAction.validator("Hello"))
        XCTAssertFalse(lengthAction.validator(""))
        XCTAssertFalse(lengthAction.validator(String(repeating: "a", count: 100)))
    }
}
#endif

