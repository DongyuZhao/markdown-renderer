import cmark_gfm
import Foundation

// swiftlint:disable discouraged_none_name

public enum MarkdownTableFlow: Sendable {
  case none, left, center, right
}

// swiftlint:enable discouraged_none_name

public struct MarkdownTableCell: Sendable {
  public let children: [MarkdownElement]

  public init(children: [MarkdownElement]) {
    self.children = children
  }

  init(from node: OpaquePointer) {
    self.init(children: node.children())
  }
}

public struct MarkdownTableRow: Sendable {
  public let cells: [MarkdownTableCell]

  public init(cells: [MarkdownTableCell]) {
    self.cells = cells
  }

  init(from node: OpaquePointer) {
    var cells: [MarkdownTableCell] = []

    var child = cmark_node_first_child(node)
    while let current = child {
      if current.typeString == "table_cell" {
        cells.append(MarkdownTableCell(from: current))
      }
      child = cmark_node_next(current)
    }

    self.init(cells: cells)
  }
}

public struct MarkdownElementTable: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let header: MarkdownTableRow
  public let rows: [MarkdownTableRow]
  public let flows: [MarkdownTableFlow]

  public init(
    header: MarkdownTableRow,
    rows: [MarkdownTableRow],
    flows: [MarkdownTableFlow],
    position: MarkdownSourcePosition = .zero
  ) {
    self.header = header
    self.rows = rows
    self.flows = flows
    self.position = position
  }

  init(from node: OpaquePointer) {
    var header = MarkdownTableRow(cells: [])
    var rows: [MarkdownTableRow] = []

    var child = cmark_node_first_child(node)
    while let current = child {
      if current.typeString == "table_row" {
        let row = MarkdownTableRow(from: current)
        if cmark_gfm_extensions_get_table_row_is_header(current) != 0 {
          header = row
        } else {
          rows.append(row)
        }
      }
      child = cmark_node_next(current)
    }

    self.init(header: header, rows: rows, flows: node.flows, position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
