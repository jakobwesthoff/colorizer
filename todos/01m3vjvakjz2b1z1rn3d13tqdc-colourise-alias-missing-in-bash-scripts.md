# Bug: `colourise` does not exist in bash scripts

**Priority:** bug

The README says `colourise` can be used in place of `colorize` "without
thinking about it". In a bash script it is not found:

```
./script: line 3: colourise: command not found      (status 127)
```

Checked with bash 5.3.20 and 3.2.57, running a script file that sources the
library and calls `colourise`. In zsh 5.9.2 and busybox ash the same script
works. In bash it works only after `shopt -s expand_aliases`.

## Cause

`colourise` is an alias (`colorizer.sh:198`: `alias colourise=colorize`).
bash does not expand aliases in non-interactive shells unless
`expand_aliases` is set, so scripts never see it. Interactive bash, zsh and
ash expand it.

## Test that detects it

`tests/loading.bats` pins today's behaviour ("the colourise alias: works
in zsh and ash scripts, not in bash scripts"). Once fixed, replace that
test with this one. It fails today in bash and passes in zsh and ash:

```bash
@test "colourise works in scripts of every shell" {
  run -0 run_script_in_test_shell "COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colourise '<red>x</red>'"

  assert_output '^[[0;31mx^[[0m'
}
```

## Proposal (input, not decided)

Replace the alias with a function:

```bash
# Alternate spelling
colourise() {
    colorize "$@"
}
```

Tried on 2026-10-01 by patching the library temporarily: the test above
passes in bash 5.3.20, bash 3.2.57, zsh 5.9.2 and busybox ash, and of the
existing suite only the test pinning this bug changes.

## Backwards compatibility

`colourise` becomes a function instead of an alias, which callers can see
through `type colourise`, `alias` and `unalias`. A caller's own `colourise`
function defined before loading would be replaced by the library's; with
the alias it is not, in bash scripts. Neither case was tested.

## Decision

_Not yet established._
