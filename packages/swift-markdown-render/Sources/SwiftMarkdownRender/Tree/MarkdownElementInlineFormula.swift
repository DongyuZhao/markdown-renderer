import cmark_gfm
import Foundation

public enum MarkdownFormulaMode: Sendable {
  case embedded, standalone

  init(from node: OpaquePointer) {
    switch cmark_gfm_extensions_get_formula_mode(node) {
    case CMARK_FORMULA_MODE_STANDALONE:
      self = .standalone
    default:
      self = .embedded
    }
  }
}

public struct MarkdownElementInlineFormula: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let literal: String
  public let mode: MarkdownFormulaMode

  public init(literal: String, mode: MarkdownFormulaMode = .embedded, position: MarkdownSourcePosition = .zero) {
    self.position = position
    self.literal = literal
    self.mode = mode
  }

  init(from node: OpaquePointer) {
    self.init(literal: node.formula, mode: MarkdownFormulaMode(from: node), position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
