# Bug: zsh interprets backslash sequences twice

**Priority:** bug

In zsh, backslash sequences in the text are interpreted twice, so the output
differs from bash and busybox ash:

| Input | bash, ash | zsh |
|---|---|---|
| `colorize 'a\\b'` | `a\b` | `a` followed by a backspace (`a^H`) |
| `colorize 'a\cb'` | `a`, no newline | `a` and a newline |

## Cause

`COLORIZER_process_input` returns its result with a plain
`echo "${result}"` (`colorizer.sh:151`), and `colorize` prints that with
`echo -e` (line 193; `echo -en` on line 191). zsh's `echo` interprets
backslash sequences without `-e` unless the `BSD_ECHO` option is set, so in
zsh the first `echo` already turns `\\` into `\` and the second one turns
`\b` into a backspace. With `\c`, the first `echo` cuts the text and drops
its newline; the second prints what is left plus a newline. Checked with
zsh 5.9.2: `echo "a\\\\b"` prints `a\b`, and `a\\b` with `setopt BSD_ECHO`.

## Test that detects it

`tests/text.bats` pins today's behaviour per shell ("an escaped backslash"
and "\\c ends the output"). Once fixed, replace those two tests with this
one, which fails in zsh 5.9.2 today and passes in bash 5.3.20 and 3.2.57
(ash gives the same output as bash for both inputs in `tests/text.bats`):

```bash
@test "backslash sequences are interpreted once, in every shell" {
  run colorize_in_test_shell 'a\\b'

  assert_status 0
  assert_output 'a\b'

  run colorize_in_test_shell_showing_line_ends 'a\cb'

  assert_status 0
  assert_output 'a'
}
```

## Proposal (input, not decided)

Return the result with `printf '%s\n' "${result}"` on line 151, so only
`colorize`'s own `echo -e` interprets. The parser rewrite
(`01m3vfmxyb4fxzzgvq1wyw1jt5`) returns the result in a variable, which
removes the first `echo` entirely.

## Decision

_Not yet established._
