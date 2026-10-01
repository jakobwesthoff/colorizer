# Bug: loading under `set -u` fails in zsh and busybox ash

**Priority:** bug

A script that turns on `set -u` (nounset) before sourcing the library:

- **bash** 5.3.20 / 3.2.57: works.
- **zsh** 5.9.2: prints
  `compatibility.sh:32: BASH_VERSION: parameter not set`, stops reading the
  compatibility layer but goes on loading `colorizer.sh`. `colorize` then
  runs without the `ARRAY_*` functions (`command not found: ARRAY_define`
  and others) and prints `Mismatching colorize tag nesting at <>...</red>`
  instead of the text, with status 0.
- **busybox ash**: the same error ends the script.

`set -u` after loading works in all four shells (`tests/loading.bats`).
Commit f661969 fixed a nounset problem in the bash compatibility layer; the
shell detection was not covered.

## Cause

`Library/Compatibility/compatibility.sh` picks the layer with
`[ -n "${BASH_VERSION}" ]` (line 32) and `[ -n "${ZSH_VERSION}" ]`
(line 34). Outside bash, `BASH_VERSION` is unset, which `set -u` turns into
an error.

## Test that detects it

`tests/loading.bats` pins today's behaviour ("set -u before loading: works
in bash, breaks colorize in zsh, ends ash"). Once fixed, replace that test
with this one. It fails today in zsh and ash and passes in bash:

```bash
@test "set -u before loading works in every shell" {
  run run_script_in_test_shell "set -u
COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colorize '<red>x</red>'"

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}
```

## Proposal (input, not decided)

Default both variables to empty: `"${BASH_VERSION:-}"` and
`"${ZSH_VERSION:-}"`. Tried on 2026-10-01 by patching the library
temporarily: the test above passes in bash 5.3.20, bash 3.2.57, zsh 5.9.2
and busybox ash, and of the existing suite only the test pinning this bug
changes.

## Decision

_Not yet established._
