import cmark_gfm
import Foundation

public struct MarkdownElementImage: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let children: [MarkdownElement]
  public let source: String?
  public let title: String?

  public init(children: [MarkdownElement], source: String?, title: String?, position: MarkdownSourcePosition = .zero) {
    self.children = children
    self.source = source
    self.title = title
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(children: node.children(), source: node.url, title: node.title, position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
