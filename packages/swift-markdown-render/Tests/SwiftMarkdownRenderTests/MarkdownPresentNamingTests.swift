import XCTest
import SwiftMarkdownRender

final class MarkdownPresentNamingTests: XCTestCase {
  func testPresentationTypesUseMarkdownPresentNames() {
    let span = MarkdownPresentTextSpan(text: "hello", format: [.bold])
    let run = MarkdownPresentRun.text(span)
    let section = MarkdownPresentTextSection(describer: .paragraph, runs: [run])
    let text = MarkdownPresentText(sections: [section])
    let trace = MarkdownPresentTrace(line: 1, column: 1, describer: .text)
    let component = MarkdownPresent.text(id: trace, text)

    XCTAssertEqual(component.id, trace)
  }

  func testPresentationTableTypesUseMarkdownPresentNames() {
    let cell = MarkdownPresentTableCell(runs: [.text(MarkdownPresentTextSpan(text: "cell"))])
    let table = MarkdownPresentTable(header: [cell], rows: [[cell]], flows: [.left])

    XCTAssertEqual(table.header, [cell])
    XCTAssertEqual(table.flows, [.left])
  }

  func testFormulaUsesFormulaNamingInPresentation() {
    let run = MarkdownPresentRun.formula("x + y", display: false)
    let trace = MarkdownPresentTrace(line: 2, column: 1, describer: .formula)
    let present = MarkdownPresent.formula(id: trace, "z = 1")

    XCTAssertEqual(run, .formula("x + y", display: false))
    XCTAssertEqual(present.id, trace)
  }

  func testDividerUsesDividerNamingInPresentation() {
    let trace = MarkdownPresentTrace(line: 3, column: 1, describer: .divider)
    let present = MarkdownPresent.divider(id: trace)

    XCTAssertEqual(present.id, trace)
  }

  func testDirectiveUsesDirectiveNamingInPresentation() {
    let label: [MarkdownPresentRun] = [.text(MarkdownPresentTextSpan(text: "Read me"))]
    let inline = MarkdownPresentInlineDirective(
      name: "badge",
      attributes: ["class": .string("small")],
      label: label
    )
    let run = MarkdownPresentRun.directive(inline)
    let childTrace = MarkdownPresentTrace(line: 4, column: 1, describer: .text)
    let block = MarkdownPresentDirectiveBlock(
      name: "note",
      attributes: ["id": .string("intro")],
      label: label,
      children: [.text(id: childTrace, MarkdownPresentText(sections: []))]
    )
    let trace = MarkdownPresentTrace(line: 3, column: 1, describer: .directive)
    let present = MarkdownPresent.directive(id: trace, block)

    XCTAssertEqual(run, .directive(inline))
    XCTAssertEqual(block.attributes, ["id": .string("intro")])
    XCTAssertEqual(present.id, trace)
  }
}
