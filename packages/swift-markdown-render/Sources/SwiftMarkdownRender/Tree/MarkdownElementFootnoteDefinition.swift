import cmark_gfm
import Foundation

public struct MarkdownElementFootnoteDefinition: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let id: String
  public let children: [MarkdownElement]

  public init(id: String, children: [MarkdownElement], position: MarkdownSourcePosition = .zero) {
    self.id = id
    self.children = children
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(id: node.footnote, children: node.children(), position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}