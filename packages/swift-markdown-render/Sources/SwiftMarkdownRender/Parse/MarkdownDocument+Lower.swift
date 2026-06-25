import Foundation

public extension MarkdownDocument {
  func lower() -> MarkdownParseResult {
    var lowerer = MarkdownDocumentLower()
    return lowerer.lower(self)
  }
}

/// Lowers a parsed ``MarkdownDocument`` into the render-optimized ``MarkdownPresent`` IR.
struct MarkdownDocumentLower {
  private enum Lowered {
    case opened(from: MarkdownSourcePosition, MarkdownPresentTextSection)
    case sealed(MarkdownPresent)
  }

  private var footnotes: [MarkdownPresentFootnoteDefinition] = []

  mutating func lower(_ document: MarkdownDocument) -> MarkdownParseResult {
    footnotes = []
    let presents = assemble(lower(blocks: document.children, depth: 0))
    return MarkdownParseResult(presents: presents, footnotes: footnotes)
  }

  // MARK: - Text Merge

  private func assemble(_ lowered: [Lowered]) -> [MarkdownPresent] {
    var output: [MarkdownPresent] = []
    var pending: [MarkdownPresentTextSection] = []
    var position: MarkdownSourcePosition?

    func flush() {
      guard !pending.isEmpty, let start = position else { return }
      output.append(.text(id: trace(start, .text), MarkdownPresentText(sections: pending)))
      pending = []
      position = nil
    }

    for item in lowered {
      switch item {
      case let .opened(from, section):
        if position == nil { position = from }
        pending.append(section)
      case let .sealed(component):
        flush()
        output.append(component)
      }
    }

    flush()
    return output
  }

  // MARK: - Blocks

  private mutating func lower(blocks: [MarkdownElement], depth: Int) -> [Lowered] {
    var result: [Lowered] = []
    for block in blocks {
      result.append(contentsOf: lower(block: block, depth: depth))
    }
    return result
  }

  private mutating func lower(block: MarkdownElement, depth: Int) -> [Lowered] {
    switch block {
    case let document as MarkdownDocument:
      return lower(blocks: document.children, depth: depth)

    case let paragraph as MarkdownElementParagraph:
      let runs = lower(inlines: paragraph.children)
      if let component = lifted(for: runs, position: paragraph.position) {
        return [.sealed(component)]
      }
      return [.opened(from: paragraph.position, MarkdownPresentTextSection(describer: .paragraph, runs: runs))]

    case let heading as MarkdownElementHeading:
      return [
        .opened(
          from: heading.position,
          MarkdownPresentTextSection(describer: .heading(level: heading.level), runs: lower(inlines: heading.children))
        )
      ]

    case let list as MarkdownElementList:
      return lower(list: list, depth: depth)

    case let blockquote as MarkdownElementBlockQuote:
      return [
        .sealed(
          .blockquote(
            id: trace(blockquote.position, .blockquote),
            assemble(lower(blocks: blockquote.children, depth: 0))
          )
        )
      ]

    case let rule as MarkdownElementThematicBreak:
      return [.sealed(.divider(id: trace(rule.position, .divider)))]

    case let code as MarkdownElementCodeBlock:
      return [.sealed(.code(id: trace(code.position, .code), language: code.language, code: code.literal))]

    case let formula as MarkdownElementFormulaBlock:
      return [.sealed(.formula(id: trace(formula.position, .formula), formula.literal))]

    case let table as MarkdownElementTable:
      return [.sealed(.table(id: trace(table.position, .table), lower(table: table)))]

    case let directive as MarkdownElementDirectiveBlock:
      let block = MarkdownPresentDirectiveBlock(
        name: directive.name,
        attributes: directive.attributes,
        label: lower(inlines: directive.label),
        children: assemble(lower(blocks: directive.children, depth: 0))
      )
      return [.sealed(.directive(id: trace(directive.position, .directive), block))]

    case let html as MarkdownElementHTMLBlock:
      return [.sealed(.html(id: trace(html.position, .html), html.literal))]

    case let footnote as MarkdownElementFootnoteDefinition:
      let content = assemble(lower(blocks: footnote.children, depth: 0))
      footnotes.append(MarkdownPresentFootnoteDefinition(id: footnote.id, content: content))
      return []

    default:
      return []
    }
  }

  private func lifted(for runs: [MarkdownPresentRun], position: MarkdownSourcePosition) -> MarkdownPresent? {
    guard runs.count == 1 else { return nil }
    switch runs[0] {
    case let .media(media):
      return .media(id: trace(position, .media), media)
    case .formula(let literal, display: true):
      return .formula(id: trace(position, .formula), literal)
    default:
      return nil
    }
  }

  private mutating func lower(list: MarkdownElementList, depth: Int) -> [Lowered] {
    var result: [Lowered] = []
    var number = list.start

    for item in list.items {
      result.append(contentsOf: lower(item: item, list: list, number: number, depth: depth))
      if list.flavor == .ordered {
        number += 1
      }
    }

    return result
  }

  private mutating func lower(item: MarkdownElementListItem, list: MarkdownElementList, number: Int, depth: Int) -> [Lowered] {
    var result: [Lowered] = []
    var leading = false

    for child in item.children {
      switch child {
      case let paragraph as MarkdownElementParagraph:
        let describer: MarkdownPresentTextSectionDescriber
        if leading {
          describer = .paragraph
        } else if list.flavor == .ordered {
          describer = .ordered(number: number, depth: depth, isChecked: item.isChecked)
        } else {
          describer = .bullet(depth: depth, isChecked: item.isChecked)
        }

        leading = true
        result.append(
          .opened(
            from: paragraph.position,
            MarkdownPresentTextSection(describer: describer, runs: lower(inlines: paragraph.children))
          )
        )

      case let nested as MarkdownElementList:
        result.append(contentsOf: lower(list: nested, depth: depth + 1))

      default:
        result.append(contentsOf: lower(block: child, depth: depth))
      }
    }

    if !leading {
      let describer: MarkdownPresentTextSectionDescriber =
        list.flavor == .ordered
        ? .ordered(number: number, depth: depth, isChecked: item.isChecked)
        : .bullet(depth: depth, isChecked: item.isChecked)
      result.append(.opened(from: item.position, MarkdownPresentTextSection(describer: describer, runs: [])))
    }

    return result
  }

  private func lower(table: MarkdownElementTable) -> MarkdownPresentTable {
    let header = table.header.cells.map { MarkdownPresentTableCell(runs: lower(inlines: $0.children)) }
    let rows = table.rows.map { row in row.cells.map { MarkdownPresentTableCell(runs: lower(inlines: $0.children)) } }
    let flows = table.flows.map { flow -> MarkdownPresentTableFlow in
      switch flow {
      case .left: return .left
      case .center: return .center
      case .right: return .right
      case .none: return .unspecified
      }
    }
    return MarkdownPresentTable(header: header, rows: rows, flows: flows)
  }

  // MARK: - Inlines

  private func lower(inlines: [MarkdownElement]) -> [MarkdownPresentRun] {
    var runs: [MarkdownPresentRun] = []
    append(inlines: inlines, format: [], link: nil, into: &runs)

    if runs.count >= 2, isBreak(runs[runs.count - 1]), case .formula = runs[runs.count - 2] {
      runs.removeLast()
    }

    return runs
  }

  private func append(
    inlines: [MarkdownElement],
    format: MarkdownPresentTextSpanFormat,
    link: URL?,
    into runs: inout [MarkdownPresentRun]
  ) {
    for inline in inlines {
      switch inline {
      case let text as MarkdownElementText:
        runs.append(.text(MarkdownPresentTextSpan(text: text.literal, format: format, link: link)))

      case let strong as MarkdownElementStrong:
        append(inlines: strong.children, format: format.union(.bold), link: link, into: &runs)

      case let emphasis as MarkdownElementEmphasis:
        append(inlines: emphasis.children, format: format.union(.italic), link: link, into: &runs)

      case let strike as MarkdownElementStrikethrough:
        append(inlines: strike.children, format: format.union(.strikethrough), link: link, into: &runs)

      case let code as MarkdownElementInlineCode:
        runs.append(.text(MarkdownPresentTextSpan(text: code.literal, format: format.union(.code), link: link)))

      case let markdownLink as MarkdownElementLink:
        append(link: markdownLink, format: format, into: &runs)

      case let image as MarkdownElementImage:
        if let media = media(for: image) {
          runs.append(.media(media))
        } else {
          runs.append(.text(MarkdownPresentTextSpan(text: text(from: image.children), format: format, link: link)))
        }

      case let formula as MarkdownElementInlineFormula:
        append(formula: formula, into: &runs)

      case let directive as MarkdownElementInlineDirective:
        runs.append(
          .directive(
            MarkdownPresentInlineDirective(
              name: directive.name,
              attributes: directive.attributes,
              label: lower(inlines: directive.label)
            )
          )
        )

      case let footnote as MarkdownElementFootnoteReference:
        runs.append(.footnote(MarkdownPresentFootnoteReference(id: footnote.id)))

      case is MarkdownElementSoftBreak:
        runs.append(.softBreak)

      case is MarkdownElementLineBreak:
        runs.append(.lineBreak)

      case let html as MarkdownElementInlineHTML:
        runs.append(.text(MarkdownPresentTextSpan(text: html.literal, format: format, link: link)))

      default:
        break
      }
    }
  }

  private func append(link: MarkdownElementLink, format: MarkdownPresentTextSpanFormat, into runs: inout [MarkdownPresentRun]) {
    let destination = link.destination.flatMap { URL(string: $0) }
    append(inlines: link.children, format: format, link: destination, into: &runs)
  }

  private func append(formula: MarkdownElementInlineFormula, into runs: inout [MarkdownPresentRun]) {
    guard formula.mode == .standalone else {
      runs.append(.formula(formula.literal, display: false))
      return
    }

    if let last = runs.last, !isBreak(last) {
      runs.append(.lineBreak)
    }
    runs.append(.formula(formula.literal, display: true))
    runs.append(.lineBreak)
  }

  private func isBreak(_ run: MarkdownPresentRun) -> Bool {
    switch run {
    case .softBreak, .lineBreak:
      return true
    default:
      return false
    }
  }

  // MARK: - Helpers

  private func media(for image: MarkdownElementImage) -> MarkdownPresentMedia? {
    guard let source = image.source, let thumbnail = URL(string: source) else { return nil }
    return MarkdownPresentMedia(
      alt: text(from: image.children),
      title: image.title,
      thumbnail: thumbnail,
      expansion: thumbnail
    )
  }

  private func text(from inlines: [MarkdownElement]) -> String {
    var result = ""
    for inline in inlines {
      switch inline {
      case let text as MarkdownElementText:
        result += text.literal
      case let code as MarkdownElementInlineCode:
        result += code.literal
      case let formula as MarkdownElementInlineFormula:
        result += formula.literal
      case let strong as MarkdownElementStrong:
        result += text(from: strong.children)
      case let emphasis as MarkdownElementEmphasis:
        result += text(from: emphasis.children)
      case let strike as MarkdownElementStrikethrough:
        result += text(from: strike.children)
      case let link as MarkdownElementLink:
        result += text(from: link.children)
      case let image as MarkdownElementImage:
        result += text(from: image.children)
      case let directive as MarkdownElementInlineDirective:
        result += text(from: directive.label)
      default:
        break
      }
    }
    return result
  }

  private func trace(_ position: MarkdownSourcePosition, _ describer: MarkdownPresentTrace.Describer) -> MarkdownPresentTrace {
    MarkdownPresentTrace(line: position.line, column: position.column, describer: describer)
  }
}