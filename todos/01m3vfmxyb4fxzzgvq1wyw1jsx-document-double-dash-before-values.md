# Document `--` before text that may start with a dash

**Priority:** 2 of 11 in the modernize series (cost/effectiveness order)

`colorize` parses its arguments with `getopts ":nps"`
(`colorizer.sh:178`), so text starting with `-` is taken as options:

- An unknown option runs `exit 42` (line 183) in the caller's shell, not
  in a subshell, so the calling script ends.
  `colorize "-x is a flag"; echo after` prints
  `Invalid option (-x) given to colorize` and never reaches `echo`.
- A known one is consumed: `colorize "-n"` prints nothing.

`getopts` already treats `--` as the end of the options:
`colorize -- "-n is text"` prints `-n is text`. Checked with bash 5.3.20
and 3.2.57. The README does not mention it.

`--` is not enough for text that is exactly an `echo` option (`-n`, `-e`,
`-E`, `-neE`, ...): `colorize -- "-n"` prints an empty line. That is bug
`01m3vjf7nwsj3jd7vmc4e5wb1d`; the README should only promise what `--`
covers until it is fixed.

Tests: `tests/options.bats` ("text that is an option is taken as one",
"-- ends the options", "an invalid option prints a message and ends the
calling script with 42").

## Proposal (input, not decided)

- README: a short section saying that text from variables should follow
  `--`, with an example.
- Optionally use `--` in the README's own examples that interpolate
  variables (the `-s` log example does).

## Backwards compatibility

Documentation only.

## Related

Whether `exit 42` should become `return 42` is part of the parser rewrite
(`01m3vfmxyb4fxzzgvq1wyw1jt5`).

## Decision

_Not yet established._
