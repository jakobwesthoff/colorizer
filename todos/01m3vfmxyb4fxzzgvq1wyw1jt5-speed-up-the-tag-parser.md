# Speed up the tag parser: no subshells, no `eval` per tag

**Priority:** 4 of 6 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

The major refactor of the series. The bugs that motivated it first (code
running from tag text, the endless loop, lost output, the error status) are
fixed and tested; what remains is speed and the way the parser is built:
the stack lives behind the `ARRAY_*` compatibility layer, called through
`$(...)`, and every palette lookup is an `eval`.

## Problems

- **`eval` on tag names.** The palette lookups paste the tag name into
  `eval`. Names are checked against `[A-Za-z0-9_-]*` first, so input
  cannot run code, but every lookup is still an `eval`.
- **Errors parse twice.** For malformed markup the parser exits 42 from its
  subshell, and `colorize` parses the text a second time, without the
  nesting check, to print it without its tags.
- **Speed.** Every closing tag costs several subshells (`$(ARRAY_peek)`
  twice, `$(ARRAY_count)`), plus one per call for the result and one for
  the final count. 300 lines with three tags each took 2.50 s (bash
  3.2.57), 2.85 s (bash 5.3.20) and 3.58 s (zsh 5.9.2) on macOS, measured
  2026-10-01 after the bug fixes: about 8 to 12 ms per line.

## Proposal (input, not decided)

- Stack as a plain string with a separator that cannot occur in a valid
  tag name, pushed and popped with `${stack% *}` / `${stack##* }`. No
  arrays, no `eval`, no subshell; parameter expansion that the default
  (POSIX) layer can use too.
- In place already: a tag name must match `[A-Za-z0-9_-]*`, and anything
  else between `<` and `>`, or a `<` with no `>` after it, is printed as
  text.
- Lookup: bash `${!name}`, zsh `${(P)name}`. The default layer has no
  indirect expansion and keeps `eval`, which is safe once the name is
  validated.
- Result in a variable (for example `COLORIZER_RESULT`) instead of
  `$(...)`, so errors can return a status.
- Keep the decided error contract (2026-10-01): messages on stderr, status
  42, the calling script goes on, and for malformed markup the text without
  its tags on stdout.
- The `ARRAY_*` functions are internal (decided 2026-10-01, README); the
  rewrite may drop them.
- The test suite (`tests/`, `just test-docker`) pins the output for every
  case; it must stay green.

## Backwards compatibility

Output for valid input must stay byte for byte the same; the tests check
that, including the error contract above.

## Related

- Enables cheap composing nesting: `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Makes the filter mode fast enough for many lines:
  `01m3vfmxyb4fxzzgvq1wyw1jt6`.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Everything it needs is in
  place: attribute and bright tags, `colorize_code`, custom tags as themes,
  and `COLORIZER_MODE`/`colorize_detect`.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 2 to 6 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is path B: speed only matters if drift sends its lines through
colorize (filter mode, `01m3vfmxyb4fxzzgvq1wyw1jt6`). On path A the jq
renderer never calls colorize per line.

## Decision

_Not yet established._
