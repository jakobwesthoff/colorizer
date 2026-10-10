---
title: "Add an opt-in nesting mode that combines styles"
kind: feature
component: library
status: needs-discussion
---
# Add an opt-in nesting mode that combines styles

Nested tags replace each other instead of combining, so a styled value inside a styled line loses the outer style. Every built-in palette value starts with `0;` (a full reset), and closing a tag re-emits only the parent's code (`colorizer.sh:142` to 150). Whether to add an opt-in mode that combines styles, and how it should behave, is not decided.

## Problem

Nested tags replace each other instead of combining. Every built-in palette value starts with `0;` (a full reset), and closing a tag re-emits only the parent's code (`colorizer.sh:142` to 150). Observed:

```
COLORIZER_bold=1
colorize "<bold>a<red>b</red>c</bold>"
^[[1ma^[[0;31mb^[[1mc^[[0m
```

`b` is red but not bold. `c` is bold and still red, because re-emitting `1` does not undo the red.

```
colorize "<bg-red>a<red>b</red></bg-red>"
^[[0;37;41ma^[[0;31mb^[[0;37;41m^[[0m
```

The background is lost under the inner colour.

An attribute inside a colour already works, because attribute codes have no `0;`: `<red><bold>x</bold></red>`.

## Proposal

Not decided.

`COLORIZER_NESTING=compose` (default: today's behaviour):

- On opening a tag, emit `0;` followed by the codes of every tag on the stack, outermost first, each with a leading `0;` removed.
- On closing, emit the same for what remains on the stack, or the reset when it is empty.
- The palette values stay as they are; stripping the `0;` while emitting keeps callers' overrides working.

Later codes win where they conflict (an inner foreground colour replaces the outer one), so same-kind nesting looks as today.

The parser rewrite in this series keeps the stack as a string, which makes joining the codes cheap.

## Backwards compatibility

Opt-in, because the output changes visibly in some cases: an outer `light-*` (`1;3x`) with an inner colour keeps the bold, where today the inner colour clears it. Making it the default would be a major version.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from colorizer instead of writing them itself. Everything it needs is in place: attribute and bright tags, `colorize_code`, custom tags as themes, and `COLORIZER_MODE`/`colorize_detect`.
- **Path B**: drift's jq program emits colorizer markup and colorize prints it. Path B needs the other todos of this series, all of them together.

Path A removes drift's own colour code without touching its renderer. Path B would also take the escape codes out of the renderer. Which path drift takes is not decided.

This todo is path B: nesting only arises when drift emits markup with a styled value inside a styled line.

## Decision

Not yet established.
