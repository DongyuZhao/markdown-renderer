import React from "react";

export type MarkdownTextProps = {
  markdown: string;
};

export function MarkdownText({ markdown }: MarkdownTextProps) {
  return <div>{markdown}</div>;
}
