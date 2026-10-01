# Add a filter mode that colours markup read from stdin

**Priority:** 11 of 11 in the modernize series (cost/effectiveness order)

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
  argument, print it. Combinable with `-s`, `-r` and the colour mode.
- Each line is self-contained: tags must close on the same line. To
  decide whether that is a rule or whether the stack carries over lines.
- Producers escape their text with `&amp;`, `&lt;`, `&gt;` (in jq:
  `gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")`).
- Alignment stays with the producer, which pads the plain text before
  wrapping it in tags.

## Dependencies

- Entities and escaping: `01m3vfmxyb4fxzzgvq1wyw1jt0`.
- Raw output, so values with backslashes survive:
  `01m3vfmxyb4fxzzgvq1wyw1jt1`.
- Composing nesting, for a styled value inside a styled line:
  `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Parser rewrite: at about 8 ms per line today, 900 lines would take
  around 7 s (`01m3vfmxyb4fxzzgvq1wyw1jt5`). How fast a bash `read` loop
  is after the rewrite has not been measured.

## Backwards compatibility

New option.

## Decision

_Not yet established._
