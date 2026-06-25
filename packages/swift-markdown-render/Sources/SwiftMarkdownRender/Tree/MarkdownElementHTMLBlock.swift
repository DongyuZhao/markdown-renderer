import cmark_gfm
import Foundation

public struct MarkdownElementHTMLBlock: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let literal: String

  public init(literal: String, position: MarkdownSourcePosition = .zero) {
    self.position = position
    self.literal = literal
  }

  init(from node: OpaquePointer) {
    self.init(literal: node.literal ?? "", position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
