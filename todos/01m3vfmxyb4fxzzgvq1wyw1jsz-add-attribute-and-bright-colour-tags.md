# Add text attribute tags and bright colour tags

**Priority:** 1 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

The palette has colours only. Text attributes (bold, dim, italic,
underline, ...) have no tags, and the `light-*` colours are bold plus the
normal colour (`1;31` for `light-red`) rather than the bright colours
(`91`).

In a terminal that does not render bold weight, `light-red` looks exactly
like `red`. This was observed in tmux with `TERM=tmux-256color`, where
`1` and `1;37` showed as plain text while dim, italic, underline, double
underline, curly underline, strikethrough, reverse and all colour modes
rendered.

ekkocli's `k8s:drift` output needed bold, dim, italic, underline and double
underline and wrote them as raw codes (`1;3;4:2`, `1;4`, `3`, `2`).

## Proposal (input, not decided)

New palette entries, defined with `:=` like the existing ones:

| Tag | Code |
|---|---|
| `bold` | `1` |
| `dim` | `2` |
| `italic` | `3` |
| `underline` | `4` |
| `double-underline` | `4:2` |
| `reverse` | `7` |
| `strike` | `9` |
| `bright-red`, `bright-green`, ... `bright-black` | `91` ... `97`, `90` |

Without a leading `0;`, so an attribute nested inside a colour keeps the
colour: `<red><bold>x</bold></red>` already works with the current parser.
The other order (`<bold><red>x</red></bold>`) loses the bold, which is the
nesting todo.

`4:2` uses a colon sub-parameter. patine's output style guide
(`jakobwesthoff/patine`, `docs/output-style.md`) uses it for double
underline and states that terminals without support fall back to a single
underline. Not checked in other terminals.

Leave `light-*` and `gray` (`1;30`) as they are.

## Backwards compatibility

New tag names only. A caller who already defined a variable with the same
name keeps their value because of `:=`. Text that uses one of these names
as an undefined tag today (which resets the colours) would get the
attribute instead.

## Related

- Combining an outer attribute with an inner colour:
  `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Several attributes in one tag without defining a custom one:
  `colorize_code` (`01m3vfmxyb4fxzzgvq1wyw1jt2`).

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is path A, first step: it gives names to the attribute codes
drift writes by hand in `_ekko_drift_colors_json` (`1;3;4:2`, `1;4`, `3`,
`2`, `1;34`). With `colorize_code` (`01m3vfmxyb4fxzzgvq1wyw1jt2`) drift can
ask for `bold italic double-underline` by name.

## Decision

_Not yet established._
