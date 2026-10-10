---
title: "Add a filter mode that colours markup read from stdin"
kind: feature
component: library
status: needs-discussion
---
# Add a filter mode that colours markup read from stdin

`colorize` takes its text as arguments, one call per message, so a program that produces many lines in another language cannot hand its output to colorizer; it has to emit escape codes itself. ekkocli's `k8s:drift` renders its output in jq, and a filter mode would let the jq program emit markup while colorizer handles codes, theme and colour mode. Whether to add the mode, and how it should work, is not decided.

## Problem

ekkocli's `k8s:drift` renders its output in jq. One release on the staging cluster had 904 hidden objects, one line each with `--show-hidden`. It receives the escape codes as a JSON object with 17 roles, built in bash, and decides about colour in bash. With a filter mode, the jq program could emit markup (`<stored>- value</stored>`) and leave codes, theme and colour mode to colorizer.

## Proposal

Not decided.

- `colorize -f`: read stdin line by line, process each line like an argument, print it. Combinable with `-s`, `-r` and `COLORIZER_MODE` (in place).
- Each line is self-contained: tags must close on the same line. To decide whether that is a rule or whether the stack carries over lines.
- Producers escape their text with `&amp;`, `&lt;`, `&gt;` (in jq: `gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;")`).
- Alignment stays with the producer, which pads the plain text before wrapping it in tags.

## Open questions

- Parser speed: at 8 to 12 ms per line (measured 2026-10-01), 900 lines would take about 7 to 11 s. How fast a bash `read` loop is after the parser rewrite has not been measured.

## Backwards compatibility

New option.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from colorizer instead of writing them itself. Everything it needs is in place: attribute and bright tags, `colorize_code`, custom tags as themes, and `COLORIZER_MODE`/`colorize_detect`.
- **Path B**: drift's jq program emits colorizer markup and colorize prints it. Path B needs the other todos of this series, all of them together.

Path A removes drift's own colour code without touching its renderer. Path B would also take the escape codes out of the renderer. Which path drift takes is not decided.

This todo is the core of path B, and depends on the todos of this series listed above.

## Decision

Not yet established.

## Relations

- Depends on: [Decode `&amp;` and add `colorize_escape` for untrusted text](01M3VFMXYB4FXZZGVQ1WYW1JT0-decode-amp-and-add-colorizeescape-for-untrusted-text.md), for entities and escaping. Tag-shaped text in a value (`<b>`) is still taken as markup unless escaped.
- Depends on: [Add a raw output option that leaves backslashes alone](01M3VFMXYB4FXZZGVQ1WYW1JT1-add-a-raw-output-option-that-leaves-backslashes-alone.md), so values with backslashes survive.
- Depends on: [Add an opt-in nesting mode that combines styles](01M3VFMXYB4FXZZGVQ1WYW1JT4-add-an-opt-in-nesting-mode-that-combines-styles.md), for a styled value inside a styled line.
- Depends on: [Speed up the tag parser: no subshells, no `eval` per tag](01M3VFMXYB4FXZZGVQ1WYW1JT5-speed-up-the-tag-parser-no-subshells-no-eval-per-tag.md), for the per-line cost.
