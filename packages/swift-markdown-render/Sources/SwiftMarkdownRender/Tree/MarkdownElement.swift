import cmark_gfm
import Foundation

public struct MarkdownSourcePosition: Hashable, Sendable {
  public let line: Int
  public let column: Int

  public static let zero = MarkdownSourcePosition(line: 0, column: 0)

  public init(line: Int, column: Int) {
    self.line = line
    self.column = column
  }

  init(startOf node: OpaquePointer) {
    self.init(line: Int(cmark_node_get_start_line(node)), column: Int(cmark_node_get_start_column(node)))
  }
}

public protocol MarkdownElement: Sendable {
  var position: MarkdownSourcePosition { get }

  func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result
}
