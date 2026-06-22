import cmark_gfm

#if canImport(SwiftUI)
import SwiftUI

public struct MarkdownText: View {
    public let markdown: String

    public init(_ markdown: String) {
        self.markdown = markdown
    }

    public var body: some View {
        // TODO: implement rendering using cmark_gfm
        EmptyView()
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
