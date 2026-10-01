# Bug: `ARRAY_peek` and `ARRAY_pop` misbehave on an empty array

**Priority:** bug (ends the calling script in ash)

On an empty array:

| | bash 5.3.20, 3.2.57 | zsh 5.9.2 | busybox ash (default layer) |
|---|---|---|---|
| `ARRAY_peek` | empty, `bad array subscript` on stderr | empty | prints `1` |
| `ARRAY_pop` in `$(...)` | empty, `bad array subscript` | empty, `assignment to invalid subscript range` | prints `1`, `bad variable name` |
| `ARRAY_pop` directly | script goes on, the errors above on stderr | script goes on, the error above on stderr | **ends the calling script**, status 2 |

colorize reads the top of an empty stack for a closing tag without an
opening one, which gives bug `01m3vjjpv54172b98ekcekpfj3` (garbage in the
error message). It does not pop an empty stack, as the mismatch check exits
first.

## Cause

Each layer computes the last index as count minus one, -1 for an empty
array, without checking:

- bash: `${list[${#list[@]}-1]}` with index -1.
- zsh: `ARRAY_pop` unsets index 0 (`list[0]=()`), which zsh rejects.
- default layer: `${list_-1}`, which the shell reads as the `${var-default}`
  expansion of `list_`, giving `1`; `unset list_-1` is an error in a special
  builtin, which ends a non-interactive POSIX shell.

## Test that detects it

`tests/compatibility.bats` pins today's behaviour ("peek and pop on an
empty array: errors in bash and zsh, a 1 in ash" and "a pop on an empty
array: harmless in bash and zsh, ends the script in ash"). Once fixed,
replace those with this one. It fails today in all four shells:

```bash
@test "peek and pop on an empty array print nothing and report no error" {
  run --separate-stderr in_test_shell 'ARRAY_define list
echo "peek: [$(ARRAY_peek list)]"
echo "pop: [$(ARRAY_pop list)]"
echo "count: $(ARRAY_count list)"'

  assert_output "$(printf 'peek: []\npop: []\ncount: 0')"
  [ -z "${stderr}" ]

  run in_test_shell 'ARRAY_define list
ARRAY_pop list > /dev/null
echo "still running, count $(ARRAY_count list)"'

  assert_status 0
  assert_output 'still running, count 0'
}
```

Whether peek and pop on an empty array should return a non-zero status is
not decided; extend the test once it is.

## Proposal (input, not decided)

Return early when `ARRAY_count` is 0, in all three layers.

## Decision

_Not yet established._
