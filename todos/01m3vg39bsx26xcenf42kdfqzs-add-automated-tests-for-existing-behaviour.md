# Add automated tests for the existing behaviour

**Priority:** before every other todo of the modernize series

colorizer has no tests and no CI. Every change in the modernize series
must keep the output for valid input the same, which the parser rewrite
(`01m3vfmxyb4fxzzgvq1wyw1jt5`) states as byte for byte. Tests that pin
today's behaviour have to exist before the first change, so that a change
in output shows up as a failing test rather than in a caller's terminal.

## Shells

The README claims bash (>3.x), zsh (>5.x) and busybox ash. Checked on
2026-10-01, sourcing `Library/colorizer.sh` and running
`colorize '<red>a<blue>b</blue>c</red>'`:

| Shell | Result |
|---|---|
| bash 5.3.20 (Homebrew), bash 3.2.57 (macOS `/bin/bash`) | works |
| zsh 5.9.2 | works |
| busybox ash, `busybox:musl` image (needs `COLORIZE_SH_SOURCE_DIR`) | works |
| dash | fails: `source: not found`, then `Bad substitution`. Not claimed by the README. |

Docker images that provide these shells, checked on 2026-10-01 on arm64:
the official `bash` image has tags per bash version (`bash:3.2` gives
3.2.57, `bash:4.4` 4.4.23, `bash:5.2` 5.2.37). It is Alpine based, so it
also has busybox ash as `/bin/sh`, and `apk add zsh bats` installs zsh 5.9
and Bats 1.12.0 into it. `zshusers/zsh` has tags per zsh version
(`5.0.8` exists).

## What the tests must cover

- Every tag in the README tables, including `none`.
- Nesting, entities (`&lt;`, `&gt;`), plain text before, between and after
  tags.
- The options `-n`, `-p`, `-s` and their combinations, and `--`.
- Custom tags through `COLORIZER_<name>`, and overriding a palette entry
  before sourcing (the `:=` defaults).
- The `colourise` alias. Aliases are not expanded in non-interactive bash
  by default; what the alias does in a script is to be found out by the
  test, not assumed.
- Loading under `set -u` (commit f661969 fixed a nounset problem).
- Error cases: mismatched and unclosed tags, an invalid option.
- The known bugs, asserted as they behave today, each pointing at the
  todo that will change it: the dashed-parent restore
  (`01m3vfmxyb4fxzzgvq1wyw1jsw`), backslash interpretation, a lone `<`,
  the swallowed `-n` value. The fixing commit then changes the expectation,
  so the diff shows the behaviour change.

## Decision

Decided 2026-10-01: bats on the host plus a Docker matrix over bash
versions, with all running logic in a `justfile`.

- One bats suite; `TEST_SHELL` names the shell under test, and
  `tests/helpers/colorize.bash` runs `colorize` in a separate process of
  that shell.
- `just test` runs it on the host (default `bash zsh`, overridable).
- `tests/docker/Dockerfile` builds on `bash:<version>` and adds zsh, bats
  and just from Alpine. `just test-docker` runs `just test` inside each
  image for `bash:3.2`, `bash:4.4`, `bash:5.2` against bash, zsh and ash.
- Expected output is written in `cat -v` form.

In place: the setup and one smoke test, passing on the host (Homebrew bash
5.3.20, macOS bash 3.2.57, zsh 5.9.2) and in all nine Docker combinations.

## Open

- The coverage list above, beyond the smoke test.
- The zsh minimum (5.0.8, `zshusers/zsh`); whether bats installs there is
  unchecked.
- CI (GitHub Actions running `just test-docker`).
- The bats version: Docker uses Alpine's package (1.12.0), the host
  whatever is installed (1.14.0 on the developer machine). Pinning bats as
  a git submodule was raised, not decided.
