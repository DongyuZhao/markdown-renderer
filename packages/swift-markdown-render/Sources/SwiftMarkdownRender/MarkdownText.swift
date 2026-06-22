import cmark_gfm

#if canImport(SwiftUI)
import SwiftUI
import Foundation

private func markdownToHTML(_ markdown: String) -> String {
    let utf8Count = markdown.utf8.count
    return markdown.withCString { ptr in
        guard let result = cmark_markdown_to_html(ptr, utf8Count, CMARK_OPT_DEFAULT) else {
            return ""
        }
        defer { free(result) }
        return String(cString: result)
    }
}

private func htmlToAttributedString(_ html: String, fallbackText: String) -> AttributedString {
    guard let data = html.data(using: .utf8),
          let attributed = try? NSAttributedString(
              data: data,
              options: [
                  .documentType: NSAttributedString.DocumentType.html,
                  .characterEncoding: String.Encoding.utf8.rawValue
              ],
              documentAttributes: nil
          ) else {
        return AttributedString(fallbackText)
    }

    return AttributedString(attributed)
}

public struct MarkdownText: View {
    private let attributedMarkdown: AttributedString

    public init(_ markdown: String) {
        let html = markdownToHTML(markdown)
        self.attributedMarkdown = htmlToAttributedString(html, fallbackText: markdown)
    }

    public var body: some View {
        Text(attributedMarkdown)
    }
}
#else
public struct MarkdownText {
    public let markdown: String

    public init(_ markdown: String) {
        self.markdown = markdown
    }
}
#endif
