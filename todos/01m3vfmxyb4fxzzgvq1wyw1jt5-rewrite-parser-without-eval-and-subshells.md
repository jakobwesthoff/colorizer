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
- **Errors replace the text.** A mismatched or unclosed tag makes the
  parser print the error as its result and exit 42 from its subshell;
  `colorize` prints that message as the line and returns 42.
- **Invalid option ends the caller.** `exit 42` in the `getopts` loop
  (line 183) runs in the caller's shell.
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
- Errors on stderr. Open: whether the invalid-option case keeps
  `exit 42`, while malformed markup returns 42 (see below).
- Keep loading the `ARRAY_*` files, in case callers use those functions.
- A test suite before the rewrite, to pin today's output for every case
  that works: the README tag tables, nesting, `-n`, `-p`, `-s`, entities.

## Backwards compatibility

Output for valid input must stay byte for byte the same; the tests above
check that. Changes only where the output is an error message today
(whether it moves to stderr). A switch from `exit` to `return` for an
invalid option would change control flow for callers that expect
`colorize` to end the script; that needs a decision.

## Related

- Enables cheap composing nesting: `01m3vfmxyb4fxzzgvq1wyw1jt4`.
- Makes the filter mode fast enough for many lines:
  `01m3vfmxyb4fxzzgvq1wyw1jt6`.

## Decision

_Not yet established._
