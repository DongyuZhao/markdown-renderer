import SwiftUI

public struct MarkdownText: View {
    private let markdown: LocalizedStringKey

    public init(_ markdown: String) {
        self.markdown = LocalizedStringKey(markdown)
    }

    public var body: some View {
        Text(markdown)
    }
}
