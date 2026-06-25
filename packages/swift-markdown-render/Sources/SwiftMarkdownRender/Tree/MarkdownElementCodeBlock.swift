import cmark_gfm
import Foundation

public struct MarkdownElementCodeBlock: MarkdownElement {
  public let position: MarkdownSourcePosition
  public let language: String?
  public let literal: String

  public init(language: String?, literal: String, position: MarkdownSourcePosition = .zero) {
    self.language = language
    self.literal = literal
    self.position = position
  }

  init(from node: OpaquePointer) {
    self.init(language: node.info, literal: node.literal ?? "", position: MarkdownSourcePosition(startOf: node))
  }

  public func accept<V: MarkdownVisitor>(visitor: inout V) -> V.Result {
    visitor.visit(self)
  }
}
