import Foundation

public protocol MarkdownVisitor {
  associatedtype Result

  // Blocks
  mutating func visit(_ node: MarkdownDocument) -> Result
  mutating func visit(_ node: MarkdownElementBlockQuote) -> Result
  mutating func visit(_ node: MarkdownElementList) -> Result
  mutating func visit(_ node: MarkdownElementListItem) -> Result
  mutating func visit(_ node: MarkdownElementCodeBlock) -> Result
  mutating func visit(_ node: MarkdownElementHTMLBlock) -> Result
  mutating func visit(_ node: MarkdownElementFormulaBlock) -> Result
  mutating func visit(_ node: MarkdownElementDirectiveBlock) -> Result
  mutating func visit(_ node: MarkdownElementParagraph) -> Result
  mutating func visit(_ node: MarkdownElementHeading) -> Result
  mutating func visit(_ node: MarkdownElementThematicBreak) -> Result
  mutating func visit(_ node: MarkdownElementTable) -> Result
  mutating func visit(_ node: MarkdownElementFootnoteDefinition) -> Result

  // Inlines
  mutating func visit(_ node: MarkdownElementText) -> Result
  mutating func visit(_ node: MarkdownElementSoftBreak) -> Result
  mutating func visit(_ node: MarkdownElementLineBreak) -> Result
  mutating func visit(_ node: MarkdownElementInlineCode) -> Result
  mutating func visit(_ node: MarkdownElementInlineHTML) -> Result
  mutating func visit(_ node: MarkdownElementInlineFormula) -> Result
  mutating func visit(_ node: MarkdownElementEmphasis) -> Result
  mutating func visit(_ node: MarkdownElementStrong) -> Result
  mutating func visit(_ node: MarkdownElementStrikethrough) -> Result
  mutating func visit(_ node: MarkdownElementLink) -> Result
  mutating func visit(_ node: MarkdownElementImage) -> Result
  mutating func visit(_ node: MarkdownElementInlineDirective) -> Result
  mutating func visit(_ node: MarkdownElementFootnoteReference) -> Result
}

public protocol MarkdownWalker: MarkdownVisitor where Result == Void {}
