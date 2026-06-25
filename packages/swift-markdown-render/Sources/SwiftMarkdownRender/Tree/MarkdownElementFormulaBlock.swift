import cmark_gfm
import Foundation

public struct MarkdownElementFormulaBlock: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let literal: String

  public init(literal: String, position: MarkdownSourcePosition = .zero) {
    self.literal = literal
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(literal: node.formula, position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
