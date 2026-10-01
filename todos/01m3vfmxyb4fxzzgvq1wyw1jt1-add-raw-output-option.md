# Add a raw output option that leaves backslashes alone

**Priority:** 7 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

`colorize` prints with `printf '%b'`, so backslash sequences in the text
are interpreted as `echo -e` would. `\n` and `\t`
become control characters, and `\c` ends the output:

```
colorize 'a\nb\tc\cd-after'
a
b	c
```

`d-after` is lost. Values from outside the script (regular expressions,
Windows paths, JSON) contain backslashes.

Some callers rely on the interpretation (for example `\n` inside a
message), so it cannot simply be switched off.

## Proposal (input, not decided)

A new option `-r`: print the processed text with `printf '%s'` instead of
`printf '%b'`, so only the tags and entities are processed. With `-n` it omits
the newline as before. `-r` is free in `getopts ":nps"`.

The escape codes themselves are built from `COLORIZER_START` (`\033[`),
which relies on the `%b` interpretation. With `-r` the start sequence has
to be the real escape character, for example `printf '%b'` applied to
`COLORIZER_START` once when building the code, not to the text.

## Backwards compatibility

New option; the default output is unchanged.

## Related

- Entity escaping for `<`, `>`, `&`: `01m3vfmxyb4fxzzgvq1wyw1jt0`.
- The parser rewrite returns the result in a variable, which makes this
  a choice of print command only: `01m3vfmxyb4fxzzgvq1wyw1jt5`.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is path B: cluster values contain backslashes, which colorize
would interpret. On path A no value reaches colorize.

## Decision

_Not yet established._
