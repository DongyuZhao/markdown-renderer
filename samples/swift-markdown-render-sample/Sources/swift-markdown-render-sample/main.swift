import SwiftMarkdownRender

let sampleMarkdown = """
# Hello, swift-markdown-render!

This is a **sample app** demonstrating the `swift-markdown-render` package.

- Item one
- Item two
- Item three
"""

let view = MarkdownText(sampleMarkdown)
print("MarkdownText created with content:\n\(view.markdown)")
