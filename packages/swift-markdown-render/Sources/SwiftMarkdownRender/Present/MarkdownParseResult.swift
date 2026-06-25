import Foundation

public struct MarkdownParseResult: Equatable, Sendable {
  public let presents: [MarkdownPresent]
  public let footnotes: [MarkdownPresentFootnoteDefinition]

  public init(
    presents: [MarkdownPresent],
    footnotes: [MarkdownPresentFootnoteDefinition] = []
  ) {
    self.presents = presents
    self.footnotes = footnotes
  }
}
