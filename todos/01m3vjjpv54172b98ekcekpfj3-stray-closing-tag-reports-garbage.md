# Bug: a closing tag without an opening one reports garbage

**Priority:** bug

For a closing tag with no open tag (`colorize 'x</red>'`), the mismatch
message depends on the shell, and bash adds an error of its own:

| Shell | stdout | stderr |
|---|---|---|
| bash 5.3.20, 3.2.57 | `Mismatching colorize tag nesting at <>...</red>` | `array.bash: line …: stack: bad array subscript` |
| zsh 5.9.2 | `Mismatching colorize tag nesting at <>...</red>` | nothing |
| busybox ash | `Mismatching colorize tag nesting at <1>...</red>` | nothing |

## Cause

The check on `colorizer.sh:106` and the message on line 107 read the top of
the stack with `ARRAY_peek`, also when the stack is empty:

- bash layer: `${stack[${#stack[@]}-1]}` with an index of -1, which bash
  reports as a bad subscript.
- default layer (ash): `${stack_-1}`, which the shell reads as the
  `${var-default}` expansion of `stack_`, giving `1`.

## Test that detects it

`tests/errors.bats` pins today's behaviour ("a closing tag without an
opening one: the message differs per shell"). Once fixed, replace that test
with this one. It fails today in bash and ash and passes in zsh:

```bash
@test "a closing tag without an opening one is reported cleanly" {
  run --separate-stderr colorize_in_test_shell 'x</red>'

  [ -z "${stderr}" ]
  assert_output 'Mismatching colorize tag nesting at <>...</red>'
}
```

The message wording is today's zsh output; a fix may word it differently
(for example naming the stray tag only), and the test should follow.

## Related

- Status and output of mismatch errors: `01m3vjjpv54172b98ekcekpfj2`.
- `ARRAY_peek` and `ARRAY_pop` on an empty array misbehave on their own as
  well (`tests/compatibility.bats`).

## Decision

_Not yet established._
