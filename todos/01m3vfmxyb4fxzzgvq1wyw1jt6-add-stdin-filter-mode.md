# Add a filter mode that colours markup read from stdin

**Priority:** 10 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

`colorize` takes its text as arguments, one call per message. A program
that produces many lines in another language cannot hand its output to
colorizer; it has to emit escape codes itself.

ekkocli's `k8s:drift` renders its output in jq. One release on the
staging cluster had 904 hidden objects, one line each with
`--show-hidden`. It receives the
escape codes as a JSON object with 17 roles, built in bash, and decides
about colour in bash. With a filter mode, the jq program could emit markup
(`<stored>- value</stored>`) and leave codes, theme and colour mode to
colorizer.

## Proposal (input, not decided)

- `colorize -f`: read stdin line by line, process each line like an
  argument, print it. Combinable with `-s`, `-r` and `COLORIZER_MODE` (in place).
- Each line is self-contained: tags must close on the same line. To
  decide whether that is a rule or whether the stack carries over lines.
- Producers escape their text with `&amp;`, `&lt;`, `&gt;` (in jq:
  `gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")`).
- Alignment stays with the producer, which pads the plain text before
  wrapping it in tags.

## Dependencies

- Entities and escaping: `01m3vfmxyb4fxzzgvq1wyw1jt0`. Tag-shaped text in
  a value (`<b>`) is still taken as markup unless escaped.
- Raw output, so values with backslashes survive:
  `01m3vfmxyb4fxzzgvq1wyw1jt1`.
- Composing nesting, for a styled value inside a styled line:
  `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Parser speed: at 8 to 12 ms per line (measured 2026-10-01), 900 lines
  would take about 7 to 11 s (`01m3vfmxyb4fxzzgvq1wyw1jt5`). How fast a
  bash `read` loop is after that work has not been measured.

## Backwards compatibility

New option.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is the core of path B, and depends on todos 6 to 9.

## Decision

_Not yet established._
