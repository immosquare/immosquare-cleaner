---
locale: en
tags:
  - app:immosquare-cleaner
  - audience:technique
---

# Markdown formatting with the built-in formatter

immosquare-cleaner formats `.md` and `.md.erb` files with its own Markdown formatter, `ImmosquareCleaner::Markdown.clean`, rather than an external tool. It applies four rules and strips trailing whitespace on every line; everything else in the file is kept exactly as written. This page describes the four rules.

## The four rules of the Markdown formatter

Each rule targets one construct and guarantees one behaviour:

| Rule               | Behaviour                                                                                                                                                                                                          |
| ------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Tables             | Every cell is padded to the width of its column and separator rows are filled with dashes. An empty cell keeps its column rather than being dropped, which would file the following values under the wrong header. |
| Lists              | A blank line is inserted after the last item of a list. A marker (`*`, `+`, `-`) only opens a list when a space follows it, so a `---` thematic break or a line opening on `*emphasis*` is left alone.             |
| Fenced code blocks | Emitted verbatim. A block only closes on a fence using the marker it opened with, so a fence of the other kind shown inside it does not end it early.                                                              |
| YAML frontmatter   | Emitted verbatim: a `---` first line followed by a matching closing `---` is YAML, not markdown. Only its leading blank lines are dropped, since they are never meaningful there.                                  |

## Markdown tables padded to their column widths

The table rule makes a Markdown table readable as plain text, which is how it is read in a diff or a terminal:

```diff
-| Format | Tool |
-|---|---|
-| Rust | rustfmt |
-| TypeScript | ESLint |
+| Format     | Tool    |
+| ---------- | ------- |
+| Rust       | rustfmt |
+| TypeScript | ESLint  |
```

A pipe escaped as `\|` inside a cell is kept as cell content, as GitHub Flavored Markdown specifies, so a cell can show an operator such as `\|\|=`. An unescaped `|` always separates two columns.

## Markdown lists closed by a blank line

The list rule separates a list from the paragraph that follows it. Without the blank line, many renderers attach the paragraph to the last list item:

```diff
 # Title
 * first
 * second
+
 Next paragraph
```

The formatter does not wrap or unwrap lines, renumber ordered lists or change list markers.
