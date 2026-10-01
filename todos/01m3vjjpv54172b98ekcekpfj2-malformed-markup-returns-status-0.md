# Bug: malformed markup prints the error as the text, with status 0

**Priority:** bug

The README says that for mismatched or missing tags "an error message
indicating the problem will be echoed back as well as an exit with
errorcode *42* will be issued". What happens instead:

- The message is printed in place of the text, on stdout.
- `colorize` returns 0, and the calling script goes on.

```
colorize '<red>x</green>'   # prints "Mismatching colorize tag nesting at <red>...</green>", status 0
colorize '<red>x'           # prints "Could not find closing tag for <red>", status 0
```

Checked with bash 5.3.20, bash 3.2.57, zsh 5.9.2 and busybox ash.

## Cause

`COLORIZER_process_input` reports both errors with `echo` and `exit 42`
(`colorizer.sh:107`/108 and 145/146). It runs inside a command substitution
(line 188), so `exit` only ends that subshell, and the message becomes the
captured result. The status is lost because the substitution is part of a
`local` declaration, whose own status (0) is what remains.

An invalid option is different: `exit 42` on line 183 runs in the caller's
shell and ends the calling script (`tests/options.bats`).

## Test that detects it

`tests/errors.bats` pins today's behaviour (the three tests naming this
todo). Once fixed, replace them with this one, which fails today in all four
shells above:

```bash
@test "malformed markup ends with status 42, as the README promises" {
  run colorize_in_test_shell '<red>x</green>'

  assert_status 42

  run colorize_in_test_shell '<red>x'

  assert_status 42
}
```

Whether the message stays on stdout or moves to stderr, and whether the
calling script should end (`exit`) or only get the status (`return`), is
not decided; extend the test once it is.

## Related

The parser rewrite (`01m3vfmxyb4fxzzgvq1wyw1jt5`) proposes returning the
result in a variable, which keeps the status.

## Decision

_Not yet established._
