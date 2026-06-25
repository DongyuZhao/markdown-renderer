import Foundation

// MARK: - Text Runs

/// One inline run — the IR's inline-level node. A paragraph's inline content is a flat `[MarkdownPresentRun]`.
/// Formatting folds into ``MarkdownPresentTextSpan``; atomic inline objects are discrete cases. Directive
/// labels carry their own text container without expanding the parent paragraph's run list.
@frozen public enum MarkdownPresentRun: Equatable, Sendable {
  /// A styled text run (covers emphasis / strong / strikethrough / inline-code / link, flattened).
  case text(MarkdownPresentTextSpan)
  /// An inline footnote reference derived directly from markdown footnote syntax.
  case footnote(MarkdownPresentFootnoteReference)
  /// Inline media (a native markdown image).
  case media(MarkdownPresentMedia)
  /// An inline directive such as `:badge[Beta]{.small}`.
  case directive(MarkdownPresentInlineDirective)
  /// Inline formula. `display` is `true` for display formula (`$$…$$`), rendered block-style; `false`
  /// for inline `$…$`. A paragraph whose sole content is display formula is promoted to a `.formula`
  /// block; in-flow display formula stays here (`display: true`), isolated on its own line with hard breaks.
  case formula(String, display: Bool)
  /// A soft line break (rendered as a space / wrap point).
  case softBreak
  /// A hard line break.
  case lineBreak
}

/// Composable inline formatting traits. At AST→IR, emphasis / strong / strikethrough / inline-code
/// are *flattened* into this trait set on text runs, so ``MarkdownPresentRun`` stays non-recursive.
public struct MarkdownPresentTextSpanFormat: OptionSet, Hashable, Sendable {
  public let rawValue: Int

  public init(rawValue: Int) { self.rawValue = rawValue }

  public static let bold = MarkdownPresentTextSpanFormat(rawValue: 1 << 0)
  public static let italic = MarkdownPresentTextSpanFormat(rawValue: 1 << 1)
  public static let strikethrough = MarkdownPresentTextSpanFormat(rawValue: 1 << 2)
  /// Inline `code` span (monospace).
  public static let code = MarkdownPresentTextSpanFormat(rawValue: 1 << 3)
}

/// A flattened styled text span — the payload of a `.text` run. A link is a *span trait* (a span can
/// be a link AND bold) rather than nesting, so links also collapse into the span's traits.
public struct MarkdownPresentTextSpan: Equatable, Sendable {
  public let text: String
  public let format: MarkdownPresentTextSpanFormat
  /// The link destination, if this run is part of a link span.
  public let link: URL?

  public init(text: String, format: MarkdownPresentTextSpanFormat = [], link: URL? = nil) {
    self.text = text
    self.format = format
    self.link = link
  }
}

/// A media unit — a static thumbnail that expands to a richer view. This is the payload of a markdown
/// `![](url)` **image** (the `.media` block and the `.media` run). A plain image expands to itself; Pass 3 may upgrade
/// `expansion` in place if a resolved chart reference matches the url.
///
/// "Chart-ness" is **not** carried here. Whether an expansion renders as an image or an interactive
/// chart is a render-layer decision derived from the URL's file extension (`.json` → chart). The IR
/// therefore carries the **unmodified** URLs so that extension is preserved; the renderer also owns
/// any fetch-path normalization (stripping a trailing filename, SharePoint direct paths).
public struct MarkdownPresentMedia: Equatable, Sendable {
  /// Alt text from `![alt]`, or a resolved reference's display text — used for accessibility and as
  /// the expanded view's title.
  public let alt: String
  /// Optional caption (the markdown image title attribute).
  public let title: String?
  /// Unmodified thumbnail (inline preview) URL.
  public let thumbnail: URL
  /// Unmodified expansion URL. Equal to ``thumbnail`` when there is no richer expansion (a plain
  /// image expands to itself); a distinct URL when a chart reference supplies one.
  public let expansion: URL

  public init(alt: String, title: String? = nil, thumbnail: URL, expansion: URL) {
    self.alt = alt
    self.title = title
    self.thumbnail = thumbnail
    self.expansion = expansion
  }
}

/// An inline footnote reference derived directly from markdown footnote syntax (for example `[^note]`).
public struct MarkdownPresentFootnoteReference: Equatable, Sendable {
  /// Footnote identifier from markdown.
  public let id: String

  public init(id: String) {
    self.id = id
  }
}

/// A block-level footnote definition derived from markdown footnote syntax.
public struct MarkdownPresentFootnoteDefinition: Equatable, Sendable {
  public let id: String
  public let content: [MarkdownPresent]

  public init(id: String, content: [MarkdownPresent]) {
    self.id = id
    self.content = content
  }
}

/// An inline directive derived from markdown directive syntax. `label` holds the bracketed directive label.
public struct MarkdownPresentInlineDirective: Equatable, Sendable {
  public let name: String
  public let attributes: MarkdownDirectiveAttributes?
  public let label: [MarkdownPresentRun]

  public init(
    name: String,
    attributes: MarkdownDirectiveAttributes? = nil,
    label: [MarkdownPresentRun] = []
  ) {
    self.name = name
    self.attributes = attributes
    self.label = label
  }
}

/// A block directive derived from markdown directive syntax. `label` holds the bracketed directive label;
/// `children` holds nested block content.
public struct MarkdownPresentDirectiveBlock: Equatable, Sendable {
  public let name: String
  public let attributes: MarkdownDirectiveAttributes?
  public let label: [MarkdownPresentRun]
  public let children: [MarkdownPresent]

  public init(
    name: String,
    attributes: MarkdownDirectiveAttributes? = nil,
    label: [MarkdownPresentRun] = [],
    children: [MarkdownPresent] = []
  ) {
    self.name = name
    self.attributes = attributes
    self.label = label
    self.children = children
  }
}

// MARK: - Text sections

/// Describes a ``MarkdownPresentTextSection`` inside a merged `.text` segment — paragraph / heading /
/// list item (bullet / ordered). These are section *kinds* here (not separate top-level blocks) so their
/// text merges into one selectable container. A blockquote is *not* a section kind: it lowers to its own
/// ``MarkdownPresent/blockquote(id:_:)`` segment — a separate selection container — so its quoted
/// headings / lists keep their structure.
///
/// The item's *content* is the section's `runs`; a list-item case carries only how to render its
/// marker / indent / checkbox.
@frozen public enum MarkdownPresentTextSectionDescriber: Equatable, Sendable {
  case paragraph
  case heading(level: Int)
  /// An unordered (bullet) list item. `depth` is 0-based nesting; `isChecked` is the task-list checkbox
  /// state — `nil` when the item is not a task-list entry, otherwise `false` (unchecked) / `true` (checked).
  case bullet(depth: Int, isChecked: Bool?)
  /// An ordered list item. `number` is the 1-based ordinal within its list; `depth` is 0-based nesting;
  /// `isChecked` is the task-list checkbox state — `nil` when not a task-list entry, else `false` / `true`.
  case ordered(number: Int, depth: Int, isChecked: Bool?)
}

/// One section (paragraph / heading / list item / blockquote) inside a `.text` segment, holding a flat
/// run of inlines.
public struct MarkdownPresentTextSection: Equatable, Sendable {
  public let describer: MarkdownPresentTextSectionDescriber
  public let runs: [MarkdownPresentRun]

  public init(describer: MarkdownPresentTextSectionDescriber, runs: [MarkdownPresentRun]) {
    self.describer = describer
    self.runs = runs
  }
}

/// A merged run of consecutive text-renderable blocks, rendered in **one** selectable text container
/// so selection / copy flows across paragraphs. Non-text blocks break the run into their own
/// ``MarkdownPresent`` segments.
public struct MarkdownPresentText: Equatable, Sendable {
  public let sections: [MarkdownPresentTextSection]

  public init(sections: [MarkdownPresentTextSection]) {
    self.sections = sections
  }
}

// MARK: - Table

/// Per-column text alignment for a ``MarkdownPresentTable``.
@frozen public enum MarkdownPresentTableFlow: Equatable, Sendable {
  case unspecified
  case left
  case center
  case right
}

/// One table cell — a flat run of inlines.
public struct MarkdownPresentTableCell: Equatable, Sendable {
  public let runs: [MarkdownPresentRun]

  public init(runs: [MarkdownPresentRun]) {
    self.runs = runs
  }
}

/// A table: header row, body rows, and per-column alignment.
public struct MarkdownPresentTable: Equatable, Sendable {
  public let header: [MarkdownPresentTableCell]
  public let rows: [[MarkdownPresentTableCell]]
  public let flows: [MarkdownPresentTableFlow]

  public init(
    header: [MarkdownPresentTableCell],
    rows: [[MarkdownPresentTableCell]],
    flows: [MarkdownPresentTableFlow]
  ) {
    self.header = header
    self.rows = rows
    self.flows = flows
  }
}

// MARK: - Components

/// Stable identity for a ``MarkdownPresent`` segment: the **start position** (1-based line/column) of
/// the first block it was lowered from, tupled with a ``Describer`` tag.
///
/// Identity vs. value — two distinct SwiftUI jobs that must not be conflated:
/// - **Identity** (this trace, used as `Identifiable.id`) answers *"is this the same view?"*. A stable id lets
///   SwiftUI update a block **in place**; a changed id tears the view down and rebuilds it, losing transient
///   state (focus, animation, in-flight image loads).
/// - **Redraw** is driven by the component's **value**: `MarkdownPresent` is `Equatable` over its
///   *payload*, so a kept-identity block re-renders whenever its content changes. The identity does **not**
///   need to encode the content to trigger a redraw — the value diff already does.
///
/// The start position is the right *identity* for the streaming diff because streaming is **append-only**: the
/// in-progress tail block keeps a fixed start as its content grows, so it holds one identity and updates in
/// place every token (its value — hence its rendering — still changes). Deriving the identity from the block's
/// *content* (raw source, or a hash) does the opposite: it re-keys the most update-heavy block on every token,
/// forcing a teardown where an in-place update was wanted. A start position does churn on a pure *move* (a
/// finished block shoved to new line numbers by an edit above it), but in append-only streaming nothing is
/// inserted above the tail, so finished blocks never move — that churn is rare and accepted. The ``Describer``
/// disambiguates same-position blocks of different kinds.
///
/// > Renderer contract: detect redraw from the **whole component value**, never from the trace alone — keying
/// > redraw on the identity would silence the streaming tail (stable id) and re-key it on a content-derived id
/// > (teardown). See the design doc's Streaming section.
public struct MarkdownPresentTrace: Hashable, Sendable {
  /// 1-based line of the first originating block's start in the parsed source. For a merged `.text` segment,
  /// the first section's start line. With ``column`` and ``describer``, this is the segment's render identity.
  public let line: Int
  /// 1-based column of the first originating block's start.
  public let column: Int
  /// What the segment is, disambiguating same-position blocks of different kinds.
  public let describer: Describer

  @frozen public enum Describer: Hashable, Sendable {
    case text
    case table
    case code
    case formula
    case blockquote
    case html
    case media
    case directive
    case divider
  }

  public init(line: Int, column: Int, describer: Describer) {
    self.line = line
    self.column = column
    self.describer = describer
  }
}

/// Render-optimized IR for assistant markdown — the lowering target of the cmark AST.
///
/// The top level is a render **segmentation**, not a 1:1 AST tree: consecutive text-renderable blocks
/// are *merged* into one `.text` segment (so selection / copy flows across paragraphs); non-text
/// blocks *break* the run into their own segments.
///
/// > Note: This is the component-based presentation IR.
@frozen public enum MarkdownPresent: Equatable, Sendable, Identifiable {
  /// A merged, multi-paragraph text segment rendered in one selectable container.
  case text(id: MarkdownPresentTrace, MarkdownPresentText)
  /// A table; cells hold flat inline runs.
  case table(id: MarkdownPresentTrace, MarkdownPresentTable)
  /// A fenced code block.
  case code(id: MarkdownPresentTrace, language: String?, code: String)
  /// Block (display) formula.
  case formula(id: MarkdownPresentTrace, String)
  /// A blockquote: its quoted content as a nested ``MarkdownPresent`` list, rendered as its own
  /// indented sub-render. Nesting is structural — a quote inside a quote is a `.blockquote` among these
  /// children — so a quoted heading or list keeps its level / markers (vs. a flattened text section). The
  /// content is a fresh `.text`-merge context: selection flows *within* the quote but not across its
  /// boundary (the quote is its own selection container — D2-revised).
  case blockquote(id: MarkdownPresentTrace, [MarkdownPresent])
  /// A raw HTML block (rare).
  case html(id: MarkdownPresentTrace, String)
  /// A divider (`---`), rendered as its own segment and not merged into surrounding text.
  case divider(id: MarkdownPresentTrace)
  /// A block directive such as `::note[Read me]{#intro}`.
  case directive(id: MarkdownPresentTrace, MarkdownPresentDirectiveBlock)

  // Blocks whose data is NOT parsed from the markdown text — peers of the cases above, differing only
  // in provenance: an inline element promoted to its own block, pre-merge.

  /// A media block — a markdown `![](url)` image promoted to its own block (a standalone-paragraph image,
  /// lifted pre-merge for simpler layout). A plain image expands to itself; Pass 3 may upgrade its
  /// expansion from a matching chart reference (D17). An image alongside other inline content stays as
  /// `MarkdownPresentRun.media`. (A cited chart is NOT a `.media` — it is a `.citation` block.)
  case media(id: MarkdownPresentTrace, MarkdownPresentMedia)

  public var id: MarkdownPresentTrace {
    switch self {
    case .text(let id, _),
      .table(let id, _),
      .code(let id, _, _),
      .formula(let id, _),
      .blockquote(let id, _),
      .html(let id, _),
      .divider(let id),
      .directive(let id, _),
      .media(let id, _):
      return id
    }
  }
}
