import XCTest
import SwiftMarkdownRender

final class MarkdownFootnoteTests: XCTestCase {
  func testParseFootnoteNodes() {
    let document = MarkdownDocument.parse(
      """
      Hello[^note].

      [^note]: Footnote content
      """
    )

    guard let paragraph = document.children.first as? MarkdownElementParagraph else {
      return XCTFail("Expected first child to be a paragraph")
    }

    guard let reference = paragraph.children.dropFirst().first as? MarkdownElementFootnoteReference else {
      return XCTFail("Expected paragraph to contain a footnote reference")
    }
    XCTAssertEqual(reference.id, "note")

    guard let definition = document.children.last as? MarkdownElementFootnoteDefinition else {
      return XCTFail("Expected last child to be a footnote definition")
    }
    XCTAssertEqual(definition.id, "note")
    XCTAssertFalse(definition.children.isEmpty)
  }

  func testPresentUsesFootnoteNaming() {
    let reference = MarkdownPresentFootnoteReference(id: "note")
    let footnoteTrace = MarkdownPresentTrace(line: 2, column: 1, describer: .text)
    let definition = MarkdownPresentFootnoteDefinition(
      id: "note",
      content: [
        .text(
          id: footnoteTrace,
          MarkdownPresentText(
            sections: [
              MarkdownPresentTextSection(
                describer: .paragraph,
                runs: [.text(MarkdownPresentTextSpan(text: "Footnote content"))]
              )
            ]
          )
        )
      ]
    )
    let run = MarkdownPresentRun.footnote(reference)
    let trace = MarkdownPresentTrace(line: 1, column: 1, describer: .text)
    let result = MarkdownParseResult(
      presents: [.text(id: trace, MarkdownPresentText(sections: []))],
      footnotes: [definition]
    )

    XCTAssertEqual(run, .footnote(reference))
    XCTAssertEqual(result.presents.first?.id, trace)
    XCTAssertEqual(result.footnotes, [definition])
  }
}