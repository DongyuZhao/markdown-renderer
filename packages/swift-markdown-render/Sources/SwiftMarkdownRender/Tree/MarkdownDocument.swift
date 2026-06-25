import cmark_gfm
import Foundation

public struct MarkdownDocument: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let children: [MarkdownElement]

  public init(children: [MarkdownElement], position: MarkdownSourcePosition = .zero) {
    self.position = position
    self.children = children
  }

  init(from node: OpaquePointer) {
    self.init(children: node.children(), position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
