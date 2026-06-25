import cmark_gfm
import Foundation

public extension MarkdownDocument {
  static func parse(_ string: String) -> MarkdownDocument {
    cmark_gfm_core_extensions_ensure_registered()

    var options = CMARK_OPT_SMART
    options |= CMARK_OPT_UNSAFE
    options |= CMARK_OPT_GITHUB_PRE_LANG
    options |= CMARK_OPT_FOOTNOTES
    options |= CMARK_OPT_FULL_INFO_STRING
    options |= CMARK_OPT_LATEX_FORMULA_DELIMITERS
    options |= CMARK_OPT_DIRECTIVE
    options |= CMARK_OPT_SOURCEPOS

    guard let parser = cmark_parser_new(options) else {
      return MarkdownDocument(children: [])
    }

    cmark_parser_attach_syntax_extension(parser, cmark_find_syntax_extension("table"))
    cmark_parser_attach_syntax_extension(parser, cmark_find_syntax_extension("strikethrough"))
    cmark_parser_attach_syntax_extension(parser, cmark_find_syntax_extension("autolink"))
    cmark_parser_attach_syntax_extension(parser, cmark_find_syntax_extension("tasklist"))
    cmark_parser_attach_syntax_extension(parser, cmark_find_syntax_extension("formula"))
    cmark_parser_attach_syntax_extension(parser, cmark_find_syntax_extension("directive"))

    let utf8Count = string.utf8.count
    string.withCString { cString in
      cmark_parser_feed(parser, cString, utf8Count)
    }

    guard let document = cmark_parser_finish(parser) else {
      cmark_parser_free(parser)
      return MarkdownDocument(children: [])
    }

    let root = MarkdownDocument(from: document)

    cmark_node_free(document)
    cmark_parser_free(parser)

    return root
  }
}
