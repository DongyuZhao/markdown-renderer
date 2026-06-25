import XCTest
import SwiftMarkdownRender

final class MarkdownDocumentLowerTests: XCTestCase {
  func testLowerDirectiveNodes() {
    let result = MarkdownDocument.parse(
      """
      Use :badge[Beta]{.small}.

      ::note[Read me]{#intro}
      """
    ).lower()

    guard case let .text(_, text)? = result.presents.first else {
      return XCTFail("Expected first present to be text")
    }
    guard case let .directive(inline)? = text.sections.first?.runs.dropFirst().first else {
      return XCTFail("Expected paragraph to contain inline directive")
    }
    XCTAssertEqual(inline.name, "badge")
    XCTAssertEqual(inline.attributes, ["class": .string("small")])

    guard case let .directive(_, block)? = result.presents.last else {
      return XCTFail("Expected final present to be block directive")
    }
    XCTAssertEqual(block.name, "note")
    XCTAssertEqual(block.attributes, ["id": .string("intro")])
    XCTAssertEqual(block.label, [.text(MarkdownPresentTextSpan(text: "Read me"))])
    XCTAssertTrue(block.children.isEmpty)
  }

  func testLowerFootnotes() {
    let result = MarkdownDocument.parse(
      """
      Hello[^note].

      [^note]: Footnote content
      """
    ).lower()

    guard case let .text(_, text)? = result.presents.first else {
      return XCTFail("Expected text present")
    }
    XCTAssertEqual(text.sections.first?.runs.dropFirst().first, .footnote(MarkdownPresentFootnoteReference(id: "note")))
    XCTAssertEqual(result.footnotes.count, 1)
    XCTAssertEqual(result.footnotes.first?.id, "note")
    guard case let .text(_, footnoteText)? = result.footnotes.first?.content.first else {
      return XCTFail("Expected footnote content to contain text present")
    }
    XCTAssertEqual(footnoteText.sections.first?.runs, [.text(MarkdownPresentTextSpan(text: "Footnote content"))])
  }

  func testLowerFootnotePreservesBlockContent() {
    let document = MarkdownDocument(
      children: [
        MarkdownElementFootnoteDefinition(
          id: "note",
          children: [
            MarkdownElementParagraph(
              children: [MarkdownElementText(literal: "Footnote content")],
              position: MarkdownSourcePosition(line: 1, column: 1)
            ),
            MarkdownElementCodeBlock(
              language: "swift",
              literal: "let value = 1",
              position: MarkdownSourcePosition(line: 3, column: 1)
            )
          ]
        )
      ]
    )
    let result = document.lower()

    XCTAssertTrue(result.presents.isEmpty)
    XCTAssertEqual(result.footnotes.count, 1)
    XCTAssertEqual(result.footnotes.first?.content.count, 2)
    guard case let .text(_, text)? = result.footnotes.first?.content.first else {
      return XCTFail("Expected first footnote block to be text")
    }
    XCTAssertEqual(text.sections.first?.runs, [.text(MarkdownPresentTextSpan(text: "Footnote content"))])
    guard case let .code(_, language, code)? = result.footnotes.first?.content.dropFirst().first else {
      return XCTFail("Expected second footnote block to be code")
    }
    XCTAssertEqual(language, "swift")
    XCTAssertEqual(code, "let value = 1")
  }

  func testLowerDividerDoesNotMergeText() {
    let document = MarkdownDocument(
      children: [
        MarkdownElementParagraph(
          children: [MarkdownElementText(literal: "Before")],
          position: MarkdownSourcePosition(line: 1, column: 1)
        ),
        MarkdownElementThematicBreak(position: MarkdownSourcePosition(line: 3, column: 1)),
        MarkdownElementParagraph(
          children: [MarkdownElementText(literal: "After")],
          position: MarkdownSourcePosition(line: 5, column: 1)
        )
      ]
    )
    let result = document.lower()

    XCTAssertEqual(result.presents.count, 3)
    guard case let .text(_, before) = result.presents[0] else {
      return XCTFail("Expected first present to be text")
    }
    XCTAssertEqual(before.sections.first?.runs, [.text(MarkdownPresentTextSpan(text: "Before"))])
    guard case .divider = result.presents[1] else {
      return XCTFail("Expected divider to be its own present")
    }
    guard case let .text(_, after) = result.presents[2] else {
      return XCTFail("Expected final present to be text")
    }
    XCTAssertEqual(after.sections.first?.runs, [.text(MarkdownPresentTextSpan(text: "After"))])
  }

  func testLowerStandaloneFormulaAndImage() {
    let formula = MarkdownElementParagraph(
      children: [MarkdownElementInlineFormula(literal: "x + y", mode: .standalone)],
      position: MarkdownSourcePosition(line: 1, column: 1)
    )
    let image = MarkdownElementParagraph(
      children: [
        MarkdownElementImage(
          children: [MarkdownElementText(literal: "Chart")],
          source: "https://example.com/chart.png",
          title: "Preview",
          position: MarkdownSourcePosition(line: 3, column: 1)
        )
      ],
      position: MarkdownSourcePosition(line: 3, column: 1)
    )
    let result = MarkdownDocument(children: [formula, image]).lower()

    XCTAssertEqual(result.presents.count, 2)
    guard case let .formula(_, literal) = result.presents[0] else {
      return XCTFail("Expected standalone formula to lift")
    }
    XCTAssertEqual(literal, "x + y")

    guard case let .media(_, media) = result.presents[1] else {
      return XCTFail("Expected standalone image to lift")
    }
    XCTAssertEqual(media.alt, "Chart")
    XCTAssertEqual(media.title, "Preview")
    XCTAssertEqual(media.thumbnail, URL(string: "https://example.com/chart.png"))
    XCTAssertEqual(media.expansion, media.thumbnail)
  }
}