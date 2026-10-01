# Rewrite the tag parser without `eval` on input and without subshells

**Priority:** 10 of 11 in the modernize series (cost/effectiveness order)

The major refactor of the series. `COLORIZER_process_input` has several
problems that share one cause: tag text is pasted into code that is
evaluated, and the stack lives behind the `ARRAY_*` compatibility layer,
called through `$(...)`.

## Problems

- **`eval` on tag names.** The palette lookups paste the tag name into
  `eval`. Names are checked against `[A-Za-z0-9_-]*` first, so input
  cannot run code, but every lookup is still an `eval`.
- **Errors parse twice.** For malformed markup the parser exits 42 from its
  subshell, and `colorize` parses the text a second time, without the
  nesting check, to print it without its tags.
- **Speed.** Every closing tag costs several subshells (`$(ARRAY_peek)`
  twice, `$(ARRAY_count)`), plus one per call for the result and one for
  the final count. 300 lines with three tags each took 2.35 to 2.47 s
  (bash 5.3.20 and 3.2.57, macOS), about 8 ms per line.

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
- A test suite before the rewrite, to pin today's output for every case
  that works: the README tag tables, nesting, `-n`, `-p`, `-s`, entities.

## Backwards compatibility

Output for valid input must stay byte for byte the same; the tests check
that, including the error contract above.

## Related

- Enables cheap composing nesting: `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Makes the filter mode fast enough for many lines:
  `01m3vfmxyb4fxzzgvq1wyw1jt6`.

## Decision

_Not yet established._
