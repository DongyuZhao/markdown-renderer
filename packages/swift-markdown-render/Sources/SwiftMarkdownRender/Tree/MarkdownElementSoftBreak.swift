import cmark_gfm
import Foundation

public struct MarkdownElementSoftBreak: MarkdownElement {
  public let position: MarkdownSourcePosition

  public init(position: MarkdownSourcePosition = .zero) {
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
