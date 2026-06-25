import cmark_gfm
import Foundation

public struct MarkdownElementFootnoteReference: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let id: String

  public init(id: String, position: MarkdownSourcePosition = .zero) {
    self.id = id
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(id: node.footnote, position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}