import XCTest
import SwiftMarkdownRender

final class FormulaNamingTests: XCTestCase {
  func testFormulaElementsUsePublicMarkdownNaming() {
    let inline = MarkdownElementInlineFormula(literal: "x + y", mode: .embedded)
    XCTAssertEqual(inline.literal, "x + y")
    XCTAssertEqual(inline.mode, .embedded)

    let block = MarkdownElementFormulaBlock(literal: "z = 1")
    XCTAssertEqual(block.literal, "z = 1")
  }

  func testFormulaElementsConformToMarkdownElement() {
    let elements: [MarkdownElement] = [
      MarkdownElementInlineFormula(literal: "x + y"),
      MarkdownElementFormulaBlock(literal: "z = 1")
    ]

    XCTAssertEqual(elements.count, 2)
  }

  func testTextElementUsesPublicContentNaming() {
    let literal = MarkdownElementText(literal: "hello")

    XCTAssertEqual(literal.literal, "hello")
  }

  func testDirectiveElementsUsePublicMarkdownNaming() {
    let block = MarkdownElementDirectiveBlock(
      name: "note",
      attributes: ["class": .string("info")],
      label: [MarkdownElementText(literal: "Read me")],
      children: [MarkdownElementParagraph(children: [MarkdownElementText(literal: "Body")])]
    )
    XCTAssertEqual(block.name, "note")
    XCTAssertEqual(block.attributes, ["class": .string("info")])

    let inline = MarkdownElementInlineDirective(
      name: "badge",
      attributes: ["class": .string("beta")],
      label: [MarkdownElementText(literal: "Beta")]
    )
    XCTAssertEqual(inline.name, "badge")
    XCTAssertEqual(inline.attributes, ["class": .string("beta")])
  }

  func testParseDirectiveExtension() {
    let document = MarkdownDocument.parse(
      """
      Use :badge[Beta]{.small}.

      ::note[Read me]{#intro}
      """
    )

    guard let paragraph = document.children.first as? MarkdownElementParagraph else {
      return XCTFail("Expected first child to be a paragraph")
    }
    guard let inline = paragraph.children.dropFirst().first as? MarkdownElementInlineDirective else {
      return XCTFail("Expected inline directive in paragraph")
    }

    XCTAssertEqual(inline.name, "badge")
    XCTAssertEqual(inline.attributes, ["class": .string("small")])
    XCTAssertEqual((inline.label.first as? MarkdownElementText)?.literal, "Beta")

    guard let block = document.children.last as? MarkdownElementDirectiveBlock else {
      return XCTFail("Expected final child to be a directive block")
    }

    XCTAssertEqual(block.name, "note")
    XCTAssertEqual(block.attributes, ["id": .string("intro")])
    XCTAssertEqual((block.label.first as? MarkdownElementText)?.literal, "Read me")
  }
}
