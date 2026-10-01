# Document custom tags as the way to define themes

**Priority:** 3 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

Every tag is looked up as the variable `COLORIZER_<name>`, with `-`
turned into `_` (`colorizer.sh:137` and 140). So any variable a caller
sets becomes a tag, including codes the palette lacks:

```bash
COLORIZER_title="1;3;4:2"
colorize "<title>Drift report</title>"   # ESC[1;3;4:2m Drift report ESC[0m
```

The palette defaults use `${VAR:=default}` (lines 30 to 74), so a caller
can also override any built-in colour before or after loading the
library. Neither is documented; the README only lists the built-in tags.

This is the mechanism for semantic styles. ekkocli's `k8s:drift` output
uses 17 roles (`title`, `heading`, `stored`, `live`, `changed`, `dim`, ...)
and builds them as hand-written escape codes.

## Proposal (input, not decided)

README section "Custom tags and themes":

- Any `COLORIZER_<name>` variable is a tag; `-` in the tag name maps to
  `_` in the variable.
- The value is the SGR parameter list without `ESC[` and `m`.
- Built-in colours can be overridden the same way.
- Tag names are letters, digits, `_` and `-`; anything else between `<`
  and `>` is printed as text.
- What happens with an undefined tag: it emits `ESC[m`, a full reset, and
  no error.

## Backwards compatibility

Documentation only. It makes existing behaviour a public contract, so any
later rewrite must keep the `COLORIZER_<name>` lookup.

## Related

- Nested custom tags combine badly today: `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Getting a tag's raw code for other renderers:
  `01m3vfmxyb4fxzzgvq1wyw1jt2`.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is path A: drift's roles (`title`, `heading`, `stored`,
`live`, `changed`, ...) can be defined as custom tags, so the theme lives in
colorizer variables and `colorize_code title` gives the code.

## Decision

_Not yet established._
