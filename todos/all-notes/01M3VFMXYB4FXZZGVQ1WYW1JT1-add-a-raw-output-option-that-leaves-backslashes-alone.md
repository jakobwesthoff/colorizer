---
title: "Add a raw output option that leaves backslashes alone"
kind: feature
component: library
status: needs-discussion
---
# Add a raw output option that leaves backslashes alone

Backslash sequences in text passed to `colorize` are interpreted, so values from outside the script (regular expressions, Windows paths, JSON) cannot reach `colorize` unchanged. Whether to add a raw option, and how it should behave, is not decided.

## Problem

`colorize` prints with `printf '%b'`, so backslash sequences in the text are interpreted as `echo -e` would. `\n` and `\t` become control characters, and `\c` ends the output:

```
colorize 'a\nb\tc\cd-after'
a
b	c
```

`d-after` is lost. Values from outside the script (regular expressions, Windows paths, JSON) contain backslashes.

Some callers rely on the interpretation (for example `\n` inside a message), so it cannot simply be switched off.

## Proposal

Not decided.

A new option `-r`: print the processed text with `printf '%s'` instead of `printf '%b'`, so only the tags and entities are processed. With `-n` it omits the newline as before. `-r` is free in `getopts ":nps"`.

The escape codes themselves are built from `COLORIZER_START` (`\033[`), which relies on the `%b` interpretation. With `-r` the start sequence has to be the real escape character, for example `printf '%b'` applied to `COLORIZER_START` once when building the code, not to the text.

The parser rewrite in this series returns the result in a variable, which makes this a choice of print command only.

## Backwards compatibility

New option; the default output is unchanged.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from colorizer instead of writing them itself. Everything it needs is in place: attribute and bright tags, `colorize_code`, custom tags as themes, and `COLORIZER_MODE`/`colorize_detect`.
- **Path B**: drift's jq program emits colorizer markup and colorize prints it. Path B needs the other todos of this series, all of them together.

Path A removes drift's own colour code without touching its renderer. Path B would also take the escape codes out of the renderer. Which path drift takes is not decided.

This todo is path B: cluster values contain backslashes, which colorize would interpret. On path A no value reaches colorize.

## Decision

Not yet established.

## Relations

- Relates to: [Decode `&amp;` and add `colorize_escape` for untrusted text](01M3VFMXYB4FXZZGVQ1WYW1JT0-decode-amp-and-add-colorizeescape-for-untrusted-text.md), for entity escaping of `<`, `>` and `&`.
