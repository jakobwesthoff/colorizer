# Document `--` before text that may start with a dash

**Priority:** 5 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

`colorize` parses its arguments with `getopts ":nps"`
(`colorizer.sh:210`), so text starting with `-` is taken as options:

- An unknown option is reported on stderr and `colorize` returns 42 without
  printing the text: `colorize "-x is a flag"` prints only
  `Invalid option (-x) given to colorize`, on stderr.
- A known one is consumed: `colorize "-n"` prints nothing.

`getopts` already treats `--` as the end of the options:
`colorize -- "-n is text"` prints `-n is text`. Checked with bash 5.3.20
and 3.2.57. The README does not mention it.

`--` also covers text that is exactly an `echo` option (`colorize -- "-n"`
prints `-n`), since colorize prints with `printf`.

Tests: `tests/options.bats` ("text that is an option is taken as one",
"-- ends the options", "an invalid option prints a message on stderr and
returns 42").

For k8s:drift: its diff lines start with markers such as `--- stored …`
and `-   replicas: 2`, so any call that passes such a line to `colorize`
needs `--`.

## Proposal (input, not decided)

- README: a short section saying that text from variables should follow
  `--`, with an example.
- Optionally use `--` in the README's own examples that interpolate
  variables (the `-s` log example does).

## Backwards compatibility

Documentation only.

## Decision

_Not yet established._
