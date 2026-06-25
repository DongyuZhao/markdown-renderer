import cmark_gfm
import Foundation

public struct MarkdownElementHeading: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let children: [MarkdownElement]
  public let level: Int

  public init(children: [MarkdownElement], level: Int, position: MarkdownSourcePosition = .zero) {
    self.children = children
    self.level = level
    self.position = position
  }

  init(from node: OpaquePointer) {
    let level = Int(cmark_node_get_heading_level(node))
    self.init(children: node.children(), level: max(level, 1), position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
