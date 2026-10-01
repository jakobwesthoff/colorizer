# Add a raw output option that leaves backslashes alone

**Priority:** 6 of 11 in the modernize series (cost/effectiveness order)

`colorize` prints with `echo -e` / `echo -en` (`colorizer.sh:191` and
193), so backslash sequences in the text are interpreted. `\n` and `\t`
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
`echo -e`, so only the tags and entities are processed. With `-n` it omits
the newline as before. `-r` is free in `getopts ":nps"`.

The escape codes themselves are built from `COLORIZER_START` (`\033[`),
which relies on the `-e` interpretation. With `-r` the start sequence has
to be the real escape character, for example `printf '%b'` applied to
`COLORIZER_START` once when building the code, not to the text.

## Backwards compatibility

New option; the default output is unchanged.

## Related

- Entity escaping for `<`, `>`, `&`: `01m3vfmxyb4fxzzgvq1wyw1jt0`.
- The parser rewrite returns the result in a variable, which makes this
  a choice of print command only: `01m3vfmxyb4fxzzgvq1wyw1jt5`.

## Decision

_Not yet established._
