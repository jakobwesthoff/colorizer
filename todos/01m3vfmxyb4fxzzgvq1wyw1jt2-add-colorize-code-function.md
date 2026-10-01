# Add `colorize_code` to get the raw escape sequence of tags

**Priority:** 2 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

Programs that render text outside `colorize` (a jq program, awk, a
`printf` format) need the escape sequences themselves. Today they can only
read the palette variables and assemble `COLORIZER_START`, the code and
`COLORIZER_END` by hand.

ekkocli's `k8s:drift` renders its output in jq and passes the codes in as
a JSON object. It has its own helper for this
(`_ekko_drift_color_code`, `printf '%b' "${COLORIZER_START}${1}${COLORIZER_END}"`)
and writes attribute codes (`1;3;4:2`, `1;4`, `3`, `2`, `1;34`) by hand,
as the palette has no names for them.

## Proposal (input, not decided)

```
colorize_code [-v name] tag...
```

- Prints the escape sequence for one or more tags combined into one
  sequence: `colorize_code bold italic double-underline` gives
  `ESC[1;3;4:2m`.
- Tag names are looked up like in `colorize` (`COLORIZER_<name>`, `-` to
  `_`), so custom tags work.
- `none` gives the reset.
- `-v name` assigns to a variable (`printf -v` in bash) instead of
  printing, to avoid a subshell per code.
- Unknown tag: to decide whether it is an error or an empty result.
  `colorize` itself emits a reset for unknown tags.
- Respects the colour mode once that exists (`01m3vfmxyb4fxzzgvq1wyw1jt3`):
  empty output when colours are off.

Leading `0;` in palette values: when combining several tags, strip it from
all but the first, or the later ones reset the earlier ones. Same rule as
in the nesting todo.

## Backwards compatibility

New function.

## Related

- Attribute tags to combine: `01m3vfmxyb4fxzzgvq1wyw1jsz`.
- Defining semantic roles as custom tags: `01m3vfmxyb4fxzzgvq1wyw1jsy`.

## Decision

_Not yet established._
