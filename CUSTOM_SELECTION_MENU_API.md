# Custom Text Selection Menu API

## 概覽

Textual 提供了強大的 API 來自定義文字選擇選單，讓您可以在標準的「複製」和「分享」動作之外添加自己的動作。

### 平台需求

| 平台 | 最低版本 | 支援程度 |
|------|----------|----------|
| macOS | 12.0+ | ✅ 完整支援 |
| iOS/iPadOS | 16.0+ | ✅ 完整支援 |
| iOS/iPadOS | 15.x | ⚠️ 僅標準動作（Copy, Share） |

## 核心組件

### 1. TextSelectionAction

代表可以添加到文字選擇選單的自定義動作。

```swift
public struct TextSelectionAction: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let systemImage: String?  // SF Symbol
    public let validator: @Sendable (String) -> Bool
    public let handler: @Sendable (String) -> Void

    public init(
        id: String,
        title: String,
        systemImage: String? = nil,
        validator: @escaping @Sendable (String) -> Bool = { _ in true },
        handler: @escaping @Sendable (String) -> Void
    )
}
```

**參數說明：**
- `id`: 動作的唯一識別符
- `title`: 選單中顯示的標題
- `systemImage`: SF Symbol 圖示名稱
- `validator`: 決定此動作是否適用於選中文字的閉包
- `handler`: 執行動作的閉包，接收選中的文字作為參數

### 2. TextSelectionMenuConfiguration

用於配置文字選擇選單的結構。

```swift
public struct TextSelectionMenuConfiguration: Equatable, Sendable {
    public var customActions: [TextSelectionAction]
    public var position: Position

    public enum Position: Sendable {
        case before  // 自定義動作顯示在標準動作之前
        case after   // 自定義動作顯示在標準動作之後
    }

    public init(
        customActions: [TextSelectionAction] = [],
        position: Position = .after
    )
}
```

## 公開 API

### View 擴展

在 `TextualNamespace where Base: View` 中添加了兩個新方法：

#### 1. textSelectionActions(_:)

簡化版 API，用於快速添加自定義動作。

```swift
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func textSelectionActions(_ actions: [TextSelectionAction]) -> some View
```

**使用範例：**
```swift
StructuredText(markdown: content)
    .textual.textSelection(.enabled)
    .textual.textSelectionActions([
        TextSelectionAction(
            id: "translate",
            title: "Translate",
            systemImage: "translate"
        ) { selectedText in
            translateText(selectedText)
        }
    ])
```

#### 2. textSelectionMenu(_:)

完整配置版 API，可控制動作位置。

```swift
@available(tvOS, unavailable)
@available(watchOS, unavailable)
public func textSelectionMenu(_ configuration: TextSelectionMenuConfiguration) -> some View
```

**使用範例：**
```swift
StructuredText(markdown: content)
    .textual.textSelection(.enabled)
    .textual.textSelectionMenu(
        TextSelectionMenuConfiguration(
            customActions: [priorityAction, secondaryAction],
            position: .before  // 在標準動作之前顯示
        )
    )
```

## 使用範例

### 範例 1：基本自定義動作

```swift
StructuredText(markdown: "Select this text")
    .textual.textSelection(.enabled)
    .textual.textSelectionActions([
        TextSelectionAction(
            id: "uppercase",
            title: "Convert to Uppercase"
        ) { text in
            print(text.uppercased())
        }
    ])
```

### 範例 2：條件性動作

只在特定條件下顯示動作：

```swift
TextSelectionAction(
    id: "openURL",
    title: "Open URL",
    systemImage: "link",
    validator: { text in
        URL(string: text) != nil && text.hasPrefix("http")
    }
) { urlString in
    if let url = URL(string: urlString) {
        NSWorkspace.shared.open(url)  // macOS
        // UIApplication.shared.open(url)  // iOS
    }
}
```

### 範例 3：多個自定義動作

```swift
let customActions = [
    // 翻譯
    TextSelectionAction(
        id: "translate",
        title: "Translate",
        systemImage: "translate"
    ) { text in
        translateText(text)
    },

    // 網路搜尋 - 僅短文本
    TextSelectionAction(
        id: "search",
        title: "Search Web",
        systemImage: "magnifyingglass",
        validator: { $0.count < 100 }
    ) { text in
        searchWeb(text)
    },

    // 字數統計
    TextSelectionAction(
        id: "wordCount",
        title: "Count Words",
        systemImage: "number"
    ) { text in
        let count = text.components(separatedBy: .whitespaces).count
        print("Words: \(count)")
    }
]

StructuredText(markdown: content)
    .textual.textSelection(.enabled)
    .textual.textSelectionActions(customActions)
```

### 範例 4：與應用功能整合

```swift
struct NoteView: View {
    @State private var highlights: Set<String> = []

    var body: some View {
        StructuredText(markdown: content)
            .textual.textSelection(.enabled)
            .textual.textSelectionActions([
                TextSelectionAction(
                    id: "highlight",
                    title: "Add to Highlights",
                    systemImage: "highlighter"
                ) { text in
                    highlights.insert(text)
                },

                TextSelectionAction(
                    id: "createNote",
                    title: "Create Note",
                    systemImage: "note.text"
                ) { text in
                    createNoteFrom(text)
                }
            ])
    }
}
```

### 範例 5：動作位置控制

```swift
StructuredText(markdown: content)
    .textual.textSelection(.enabled)
    .textual.textSelectionMenu(
        TextSelectionMenuConfiguration(
            customActions: [
                TextSelectionAction(
                    id: "priority",
                    title: "Important Action",
                    systemImage: "star.fill"
                ) { text in
                    handlePriorityAction(text)
                }
            ],
            position: .before  // 顯示在 Copy/Share 之前
        )
    )
```

## 平台支援

### macOS
✅ 完整支援
- 自定義選單項目通過 `NSMenu` 實現
- 支援 SF Symbols 圖示（macOS 11+）
- 右鍵選單和選單欄整合
- 鍵盤選擇擴展

### iOS/iPadOS
✅ 完整支援 (iOS 16+)
- 通過 `UIEditMenuInteraction` 實現自定義動作
- 支援 SF Symbols 圖示
- 自動與系統編輯選單整合
- 驗證器控制動作可用性

⚠️ iOS 15 限制
- 自定義動作不可用（需要 iOS 16+）
- 標準複製和分享功能仍然可用

## 實現細節

### macOS (AppKit)

在 `NSTextInteractionView` 中：
- `makeContextMenu()` 構建選單
- `performCustomAction(_:)` 執行自定義動作
- 通過 `menuConfiguration` 屬性傳遞配置
- 使用 `NSMenuItem.representedObject` 儲存動作 ID

### iOS (UIKit)

在 `UITextInteractionView` 中 (iOS 16+)：
- 使用 `UIEditMenuInteraction` API
- 實現 `UIEditMenuInteractionDelegate` 協議
- `editMenuInteraction(_:menuFor:suggestedActions:)` 構建自定義選單
- 支援 SF Symbols 圖示
- 自動與系統標準動作整合

### 跨平台共享

- `TextSelectionAction`: 平台無關的動作定義
- `TextSelectionMenuConfiguration`: Environment 值
- 通過 SwiftUI Environment 傳遞配置

## 最佳實踐

### 1. 使用有意義的 ID
```swift
// ✅ 好
TextSelectionAction(id: "translate", ...)

// ❌ 不好
TextSelectionAction(id: "action1", ...)
```

### 2. 提供適當的驗證器
```swift
// ✅ 檢查文字長度和內容
TextSelectionAction(
    id: "search",
    title: "Search",
    validator: { text in
        !text.isEmpty && text.count < 200
    }
) { ... }
```

### 3. 使用 SF Symbols
```swift
// ✅ 提供視覺提示
TextSelectionAction(
    id: "bookmark",
    title: "Bookmark",
    systemImage: "bookmark.fill"
) { ... }
```

### 4. 處理錯誤
```swift
TextSelectionAction(id: "openURL", title: "Open") { urlString in
    guard let url = URL(string: urlString) else {
        print("Invalid URL")
        return
    }
    // 處理 URL...
}
```

### 5. 保持動作簡潔
```swift
// ✅ 快速、非阻塞操作
TextSelectionAction(id: "copy", title: "Copy") { text in
    pasteboard.string = text
}

// ⚠️ 對於耗時操作，使用異步處理
TextSelectionAction(id: "analyze", title: "Analyze") { text in
    Task {
        await analyzeText(text)
    }
}
```

## 限制

1. **iOS 版本要求**：
   - 自定義動作需要 iOS 16+
   - iOS 15 上只有標準動作（複製、分享）可用

2. **Sendable 要求**：
   - 閉包必須是 `@Sendable`
   - 不能捕獲非 Sendable 類型的變數

3. **選單項目數量**：
   - iOS 編輯選單有項目數量限制
   - 建議最多 5-7 個自定義動作

## 遷移指南

如果您之前直接修改了內部實現，現在可以遷移到公開 API：

### 之前（內部修改）
```swift
// ❌ 直接修改 NSTextInteractionView
class CustomNSTextInteractionView: NSTextInteractionView {
    override func makeContextMenu() -> NSMenu {
        // 自定義實現...
    }
}
```

### 現在（公開 API）
```swift
// ✅ 使用公開 API
StructuredText(markdown: content)
    .textual.textSelection(.enabled)
    .textual.textSelectionActions([
        TextSelectionAction(id: "custom", title: "Custom") { text in
            // 您的邏輯
        }
    ])
```

## 故障排除

### 問題：自定義動作未出現

**解決方案：**
1. 確保 `.textSelection(.enabled)` 已設置
2. 檢查驗證器是否返回 `true`
3. 確認已選擇文字（非空選擇）

### 問題：iOS 上動作不工作

**解決方案：**
1. 檢查 `canPerformAction` 是否返回 `true`
2. 確保動作 ID 不包含特殊字符
3. 驗證閉包是否 `@Sendable`

### 問題：macOS 上沒有圖示

**解決方案：**
- SF Symbols 需要 macOS 11+
- 檢查系統圖示名稱是否正確
- 較舊系統會優雅降級（僅顯示文字）

## 未來增強

計劃中的功能：
- [ ] 子選單支援
- [ ] 鍵盤快捷鍵
- [ ] 動作分組
- [ ] 本地化支援
- [ ] iOS 上的圖示支援改進
- [ ] 動作優先級/排序

## 相關 API

- `.textual.textSelection(_:)` - 啟用/禁用文字選擇
- `TextSelectability` - SwiftUI 的選擇能力協議
- Environment 值系統

## 參考

- [SwiftUI Environment](https://developer.apple.com/documentation/swiftui/environment)
- [NSMenu](https://developer.apple.com/documentation/appkit/nsmenu)
- [UITextInteraction](https://developer.apple.com/documentation/uikit/uitextinteraction)




