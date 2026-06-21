import React from "react";
import { MarkdownText } from "react-markdown";

const SAMPLE_MARKDOWN = `# Hello, react-markdown!

This is a **sample app** demonstrating the \`react-markdown\` package.

- Item one
- Item two
- Item three
`;

export function App() {
  return (
    <div style={{ padding: "2rem", fontFamily: "sans-serif" }}>
      <MarkdownText markdown={SAMPLE_MARKDOWN} />
    </div>
  );
}
