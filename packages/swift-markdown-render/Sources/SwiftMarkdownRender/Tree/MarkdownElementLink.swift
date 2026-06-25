import cmark_gfm
import Foundation

public struct MarkdownElementLink: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let children: [MarkdownElement]
  public let destination: String?
  public let title: String?

  public init(children: [MarkdownElement], destination: String?, title: String?, position: MarkdownSourcePosition = .zero) {
    self.children = children
    self.destination = destination
    self.title = title
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(children: node.children(), destination: node.url, title: node.title, position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
