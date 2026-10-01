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

## Proposal (input, not decided)

- README: a short section saying that text from variables should follow
  `--`, with an example.
- Optionally use `--` in the README's own examples that interpolate
  variables (the `-s` log example does).

## Backwards compatibility

Documentation only.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is general documentation. For drift it matters on path B only:
its diff lines start with markers such as `--- stored …` and
`-   replicas: 2`, so any call that passes such a line to `colorize` needs
`--`. On path A drift never calls `colorize` with its lines.

## Decision

_Not yet established._
