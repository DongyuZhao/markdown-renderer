import cmark_gfm
import Foundation

public enum MarkdownListFlavor: Sendable {
  case bullet, ordered

  init(from type: cmark_list_type) {
    self = type == CMARK_ORDERED_LIST ? .ordered : .bullet
  }
}

public struct MarkdownElementList: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let items: [MarkdownElementListItem]
  public let flavor: MarkdownListFlavor
  public let isTight: Bool
  public let start: Int

  public init(
    items: [MarkdownElementListItem],
    flavor: MarkdownListFlavor,
    isTight: Bool,
    start: Int,
    position: MarkdownSourcePosition = .zero
  ) {
    self.position = position
    self.items = items
    self.flavor = flavor
    self.isTight = isTight
    self.start = start
  }

  init(from node: OpaquePointer) {
    self.init(
      items: node.children().compactMap { $0 as? MarkdownElementListItem },
      flavor: MarkdownListFlavor(from: cmark_node_get_list_type(node)),
      isTight: cmark_node_get_list_tight(node) != 0,
      start: Int(cmark_node_get_list_start(node)),
      position: MarkdownSourcePosition(startOf: node)
    )
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}

public struct MarkdownElementListItem: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let children: [MarkdownElement]
  public let isChecked: Bool?

  public init(children: [MarkdownElement], isChecked: Bool?, position: MarkdownSourcePosition = .zero) {
    self.children = children
    self.isChecked = isChecked
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(children: node.children(), isChecked: node.checked, position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
