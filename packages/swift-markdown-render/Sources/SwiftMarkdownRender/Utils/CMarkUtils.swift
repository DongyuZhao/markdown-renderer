import cmark_gfm
import Foundation

extension OpaquePointer {
  var literal: String? {
    cmark_node_get_literal(self).flatMap { String(cString: $0) }
  }

  var url: String? {
    cmark_node_get_url(self).flatMap { String(cString: $0) }
  }

  var title: String? {
    cmark_node_get_title(self).flatMap { String(cString: $0) }
  }

  var formula: String {
    cmark_gfm_extensions_get_formula_literal(self).flatMap { String(cString: $0) } ?? ""
  }

  var name: String {
    cmark_gfm_extensions_get_directive_name(self).flatMap { String(cString: $0) } ?? ""
  }

  var attributes: MarkdownDirectiveAttributes? {
    guard
      let jsonString = cmark_gfm_extensions_get_directive_attributes(self)
        .flatMap({ String(cString: $0) })?
        .trimmingCharacters(in: .whitespacesAndNewlines),
      !jsonString.isEmpty,
      let data = jsonString.data(using: .utf8),
      let object = try? JSONSerialization.jsonObject(with: data),
      let dictionary = object as? [String: Any]
    else {
      return nil
    }

    return dictionary.mapValues(MarkdownDirectiveAttributeValue.init(any:))
  }

  var typeString: String {
    cmark_node_get_type_string(self).flatMap { String(cString: $0) } ?? "unknown"
  }

  var footnote: String {
    if cmark_node_get_type(self) == CMARK_NODE_FOOTNOTE_REFERENCE,
       let definition = cmark_node_parent_footnote_def(self),
       let id = definition.literal,
       !id.isEmpty {
      return id
    }

    return literal ?? ""
  }

  /// The code-fence language (info string), or `nil` when absent or empty.
  var info: String? {
    cmark_node_get_fence_info(self)
      .flatMap { String(cString: $0) }
      .flatMap { $0.isEmpty ? nil : $0 }
  }

  /// Per-column alignment flows for a table node. Columns without an explicit
  /// alignment default to `.none`; empty when the node reports no columns.
  var flows: [MarkdownTableFlow] {
    let columnCount = Int(cmark_gfm_extensions_get_table_columns(self))
    guard columnCount > 0, let raw = cmark_gfm_extensions_get_table_alignments(self) else {
      return columnCount > 0 ? Array(repeating: MarkdownTableFlow.none, count: columnCount) : []
    }

    return (0..<columnCount).map { index in
      switch raw[index] {
      case UInt8(ascii: "l"): return .left
      case UInt8(ascii: "r"): return .right
      case UInt8(ascii: "c"): return .center
      default: return .none
      }
    }
  }

  /// Whether this GFM task-list item's checkbox is checked, or `nil` when the node is not a
  /// task-list item (i.e. has no checkbox).
  var checked: Bool? {
    guard let parent = cmark_node_parent(self), cmark_node_get_type(parent) == CMARK_NODE_LIST else {
      return nil
    }

    let typeString = cmark_node_get_type_string(self).flatMap { String(cString: $0) }
    guard typeString == "tasklist" else { return nil }

    return cmark_gfm_extensions_get_tasklist_item_checked(self)
  }

  /// Builds Markdown elements from this node's direct children, dispatching each
  /// child to its matching element type. Unsupported node types are skipped.
  func children() -> [MarkdownElement] {
    var result: [MarkdownElement] = []
    var child = cmark_node_first_child(self)
    while let current = child {
      if let element = current.element() {
        result.append(element)
      }
      child = cmark_node_next(current)
    }
    return result
  }

  func label() -> [MarkdownElement] {
    var result: [MarkdownElement] = []
    var child = cmark_node_first_child(self)
    while let current = child {
      if current.typeString == "directive_label" {
        result.append(contentsOf: current.children())
      }
      child = cmark_node_next(current)
    }
    return result
  }

  func container() -> [MarkdownElement] {
    var result: [MarkdownElement] = []
    var child = cmark_node_first_child(self)
    while let current = child {
      if current.typeString != "directive_label", let element = current.element() {
        result.append(element)
      }
      child = cmark_node_next(current)
    }
    return result
  }

  func element() -> MarkdownElement? {
    switch cmark_node_get_type(self) {
    case CMARK_NODE_DOCUMENT: return MarkdownDocument(from: self)
    case CMARK_NODE_BLOCK_QUOTE: return MarkdownElementBlockQuote(from: self)
    case CMARK_NODE_LIST: return MarkdownElementList(from: self)
    case CMARK_NODE_ITEM: return MarkdownElementListItem(from: self)
    case CMARK_NODE_PARAGRAPH: return MarkdownElementParagraph(from: self)
    case CMARK_NODE_HEADING: return MarkdownElementHeading(from: self)
    case CMARK_NODE_CODE_BLOCK: return MarkdownElementCodeBlock(from: self)
    case CMARK_NODE_HTML_BLOCK: return MarkdownElementHTMLBlock(from: self)
    case CMARK_NODE_THEMATIC_BREAK: return MarkdownElementThematicBreak(from: self)
    case CMARK_NODE_FOOTNOTE_DEFINITION: return MarkdownElementFootnoteDefinition(from: self)
    case CMARK_NODE_TEXT: return MarkdownElementText(from: self)
    case CMARK_NODE_SOFTBREAK: return MarkdownElementSoftBreak(from: self)
    case CMARK_NODE_LINEBREAK: return MarkdownElementLineBreak(from: self)
    case CMARK_NODE_CODE: return MarkdownElementInlineCode(from: self)
    case CMARK_NODE_HTML_INLINE: return MarkdownElementInlineHTML(from: self)
    case CMARK_NODE_EMPH: return MarkdownElementEmphasis(from: self)
    case CMARK_NODE_STRONG: return MarkdownElementStrong(from: self)
    case CMARK_NODE_LINK: return MarkdownElementLink(from: self)
    case CMARK_NODE_IMAGE: return MarkdownElementImage(from: self)
    case CMARK_NODE_FOOTNOTE_REFERENCE: return MarkdownElementFootnoteReference(from: self)
    default:
      switch typeString {
      case "table": return MarkdownElementTable(from: self)
      case "formula_block": return MarkdownElementFormulaBlock(from: self)
      case "formula_inline": return MarkdownElementInlineFormula(from: self)
      case "directive": return MarkdownElementInlineDirective(from: self)
      case "directive_container": return MarkdownElementDirectiveBlock(from: self)
      case "strikethrough": return MarkdownElementStrikethrough(from: self)
      default: return nil
      }
    }
  }
}
