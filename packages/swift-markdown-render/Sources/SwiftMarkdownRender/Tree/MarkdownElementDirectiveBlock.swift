import cmark_gfm
import Foundation

public struct MarkdownElementDirectiveBlock: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let name: String
  public let attributes: MarkdownDirectiveAttributes?
  public let label: [MarkdownElement]
  public let children: [MarkdownElement]

  public init(
    name: String,
    attributes: MarkdownDirectiveAttributes? = nil,
    label: [MarkdownElement] = [],
    children: [MarkdownElement] = [],
    position: MarkdownSourcePosition = .zero
  ) {
    self.position = position
    self.name = name
    self.attributes = attributes
    self.label = label
    self.children = children
  }

  init(from node: OpaquePointer) {
    self.init(
      name: node.name,
      attributes: node.attributes,
      label: node.label(),
      children: node.container(),
      position: MarkdownSourcePosition(startOf: node)
    )
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
