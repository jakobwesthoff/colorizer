# Bug: a tag name that is not a variable name breaks the output

**Priority:** bug

Tag names are pasted into a variable name and evaluated, so a name with a
character that is not valid there (a space, for example) is a shell syntax
error:

| Input | bash 5.3.20, 3.2.57, busybox ash | zsh 5.9.2 |
|---|---|---|
| `<red >x</red >` | empty line, `bad substitution` on stderr | `ESC[mxESC[0m` (like an undefined tag), `bad substitution` on stderr |
| `a < b` | empty line, `bad substitution` on stderr | loops forever (bug `01m3vjjpv54172b98ekcekpfj4`) |

The whole text is lost, not only the tag.

## Cause

The palette lookup builds the variable name from the tag text and
evaluates it: `eval "ansiToken=\"\${COLORIZER_${pseudoTag}}\""`
(`colorizer.sh:118`, and line 124 for the parent). With a space in the name
that is `${COLORIZER_red }`, a bad substitution. In bash and ash the error
ends the `$(...)` subshell the parser runs in (line 188), so nothing is
returned; zsh reports it and continues with an empty code.

Characters that are valid inside `${...}` are not an error but are
evaluated instead: see bug `01m3vjjpv54172b98ekcekpfj6` (tag text runs as
a command).

## Test that detects it

`tests/errors.bats` pins today's behaviour ("a tag name with a space", and
the bash/ash branch of "a < followed by a space"). Once fixed, replace
those with this one, which fails today in all four shells:

```bash
@test "a tag name that is not a variable name keeps the text and the shell quiet" {
  run --separate-stderr colorize_in_test_shell '<red >x</red >'

  [ -z "${stderr}" ]
  [[ "${output}" == *x* ]]
}
```

Whether such a name is printed as text or reported as an error is not
decided; the parser rewrite (`01m3vfmxyb4fxzzgvq1wyw1jt5`) proposes
accepting only `[A-Za-z0-9_-]+` as a tag name and printing anything else
as text. Tighten the test once decided.

## Decision

_Not yet established._
