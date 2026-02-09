# Quick Start: Custom Text Selection Menu

## 平台支援

| 平台 | 最低版本 | 自定義動作支援 |
|------|----------|----------------|
| macOS | 12.0+ | ✅ 完整支援 |
| iOS | 16.0+ | ✅ 完整支援 |
| iOS | 15.x | ❌ 僅標準動作 |

## 5 分鐘快速上手

### 1️⃣ 基本使用

```swift
import SwiftUI
import Textual

struct MyView: View {
    var body: some View {
        StructuredText(markdown: "Select **this text** to see custom actions!")
            .textual.textSelection(.enabled)
            .textual.textSelectionActions([
                TextSelectionAction(
                    id: "translate",
                    title: "Translate"
                ) { selectedText in
                    print("Translating: \(selectedText)")
                }
            ])
    }
}
```

### 2️⃣ 添加圖示

```swift
TextSelectionAction(
    id: "search",
    title: "Search Web",
    systemImage: "magnifyingglass"  // SF Symbol
) { selectedText in
    searchWeb(selectedText)
}
```

### 3️⃣ 條件性顯示

```swift
TextSelectionAction(
    id: "openURL",
    title: "Open URL",
    systemImage: "link",
    validator: { text in
        // 只對 URL 顯示
        URL(string: text) != nil
    }
) { urlString in
    if let url = URL(string: urlString) {
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}
```

### 4️⃣ 多個動作

```swift
.textual.textSelectionActions([
    // 動作 1: 翻譯
    TextSelectionAction(
        id: "translate",
        title: "Translate",
        systemImage: "translate"
    ) { text in
        translateText(text)
    },

    // 動作 2: 複製為 Markdown
    TextSelectionAction(
        id: "copyMarkdown",
        title: "Copy as Markdown",
        systemImage: "doc.text"
    ) { text in
        copyAsMarkdown(text)
    },

    // 動作 3: 分享
    TextSelectionAction(
        id: "shareText",
        title: "Share Text",
        systemImage: "square.and.arrow.up"
    ) { text in
        shareText(text)
    }
])
```

### 5️⃣ 進階：控制位置

```swift
.textual.textSelectionMenu(
    TextSelectionMenuConfiguration(
        customActions: [
            TextSelectionAction(
                id: "priority",
                title: "Important Action ⭐",
                systemImage: "star.fill"
            ) { text in
                handleImportantAction(text)
            }
        ],
        position: .before  // 在 Copy/Share 之前顯示
    )
)
```

## 🎯 常見使用場景

### 場景 1: 網路搜尋

```swift
TextSelectionAction(
    id: "googleSearch",
    title: "Search Google",
    systemImage: "magnifyingglass",
    validator: { $0.count > 0 && $0.count < 100 }
) { query in
    let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    if let url = URL(string: "https://www.google.com/search?q=\(encoded)") {
        openURL(url)
    }
}
```

### 場景 2: 添加到筆記

```swift
@State private var notes: [String] = []

// ...

.textual.textSelectionActions([
    TextSelectionAction(
        id: "addNote",
        title: "Add to Notes",
        systemImage: "note.text.badge.plus"
    ) { text in
        notes.append(text)
    }
])
```

### 場景 3: 文字轉換

```swift
.textual.textSelectionActions([
    TextSelectionAction(
        id: "uppercase",
        title: "UPPERCASE"
    ) { text in
        showResult(text.uppercased())
    },

    TextSelectionAction(
        id: "lowercase",
        title: "lowercase"
    ) { text in
        showResult(text.lowercased())
    },

    TextSelectionAction(
        id: "titleCase",
        title: "Title Case"
    ) { text in
        showResult(text.titlecased)
    }
])
```

### 場景 4: Email 處理

```swift
TextSelectionAction(
    id: "sendEmail",
    title: "Send Email",
    systemImage: "envelope",
    validator: { text in
        text.contains("@") && text.contains(".")
    }
) { email in
    if let url = URL(string: "mailto:\(email)") {
        openURL(url)
    }
}
```

### 場景 5: 統計資訊

```swift
@State private var showStats = false
@State private var stats = ""

// ...

TextSelectionAction(
    id: "stats",
    title: "Text Statistics",
    systemImage: "chart.bar"
) { text in
    let words = text.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
    let chars = text.count

    stats = """
    Words: \(words.count)
    Characters: \(chars)
    Lines: \(text.components(separatedBy: .newlines).count)
    """

    showStats = true
}
```

## 💡 小技巧

### ✅ 最佳實踐

1. **使用描述性的 ID**
   ```swift
   // ✅ 好
   id: "translateToSpanish"

   // ❌ 不好
   id: "action1"
   ```

2. **提供驗證器**
   ```swift
   validator: { text in
       !text.isEmpty && text.count < 1000
   }
   ```

3. **處理錯誤**
   ```swift
   handler: { text in
       guard !text.isEmpty else { return }
       // 處理...
   }
   ```

4. **非同步操作**
   ```swift
   handler: { text in
       Task {
           await performLongOperation(text)
       }
   }
   ```

### ⚠️ 注意事項

1. 必須先啟用文字選擇：
   ```swift
   .textual.textSelection(.enabled)  // ← 必須
   .textual.textSelectionActions([...])
   ```

2. iOS 上編輯選單項目有限制（建議最多 5-7 個）

3. 閉包必須是 `@Sendable`（不能捕獲非 Sendable 的變數）

4. SF Symbols 圖示只在 macOS 11+ 顯示

## 🔗 更多資源

- **完整 API 文檔**：`CUSTOM_SELECTION_MENU_API.md`
- **實作細節**：`IMPLEMENTATION_SUMMARY.md`
- **範例程式碼**：`Examples/TextualDemo/TextualDemo/CustomTextSelectionDemo.swift`

## 🚀 立即開始

1. 複製上面的程式碼
2. 替換成您自己的邏輯
3. 執行並測試
4. 選擇文字查看效果！

---

**需要幫助？** 查看完整文檔或參考範例程式碼。

