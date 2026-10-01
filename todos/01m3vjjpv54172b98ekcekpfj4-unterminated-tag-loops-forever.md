# Bug: a `<` with no `>` after it makes colorize loop forever

**Priority:** bug (hangs the caller)

`colorize 'a<b'` never returns, in bash 5.3.20, bash 3.2.57, zsh 5.9.2 and
busybox ash. A probe left running used a full CPU core for minutes until it
was killed. In zsh, `colorize 'a < b'` loops as well; bash and ash end that
one with a syntax error and an empty line (bug
`01m3vjjpv54172b98ekcekpfj5`).

Any text from outside the script can contain a `<` with no `>` after it: a
comparison in a log line, a heredoc arrow, a shell redirection in a
command line.

## Cause

The parser loops while the rest of the text contains a `<`
(`colorizer.sh:97`). Each pass takes the tag name up to the next `>`
(lines 99 and 100) and then cuts the text after that `>`
(line 138: `processed="${processed#*>}"`). With no `>` left, nothing is
cut, the same `<` is found again, and the loop never ends. Each pass also
appends to `result` (line 141).

The loop is left only when evaluating the tag name fails hard enough to
end the subshell: in bash and ash, a name with a space is a syntax error
in the `eval` on line 118; zsh reports that error and goes on.

The tests guard against the loop with a CPU-time limit on every shell they
start (`ulimit -t`, `tests/helpers/colorize.bash`), because the looping
process is a `$(...)` subshell that survives when its parent is killed.

## Test that detects it

`tests/errors.bats` pins today's behaviour ("a < with no > after it loops
forever", and the zsh branch of "a < followed by a space"). Once fixed,
replace those with this one, which fails today in all four shells (in bash
and ash on the first input only):

```bash
@test "a < with no > after it does not loop" {
  run colorize_with_time_limit 'a<b'

  [ "${status}" -ne 124 ]

  run colorize_with_time_limit 'a < b'

  [ "${status}" -ne 124 ]
}
```

What the output should be (the text as it is, or an error) is not decided;
the parser rewrite (`01m3vfmxyb4fxzzgvq1wyw1jt5`) proposes printing a `<`
that does not start a valid tag as text. Extend the test once decided.

## Decision

_Not yet established._
