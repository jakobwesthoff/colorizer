# Bug: `ARRAY_unset` in bash leaves a hole that breaks peek and push

**Priority:** bug

After unsetting a middle element, bash and zsh disagree, and bash's state
breaks the other functions. For `a b c` with index 1 unset, then `d`
pushed:

| | bash 5.3.20, 3.2.57 | zsh 5.9.2 |
|---|---|---|
| after unset | count 2, peek empty, get 1 empty, get 2 `c` | count 2, peek `c`, get 1 `c` |
| after push `d` | count 2, peek empty (`c` overwritten by `d` at index 2) | count 3, peek `d` |

The default layer (busybox ash) has no `ARRAY_unset`. colorize does not use
it.

## Cause

bash's `ARRAY_unset` runs `unset list[1]`, which leaves a sparse array:
the length drops to 2 while the indexes stay 0 and 2. `ARRAY_peek` reads
index length minus one (1, the hole) and `ARRAY_push` writes at index
length (2, the last element). zsh's `list[2]=()` removes the element and
moves the later ones down.

## Test that detects it

`tests/compatibility.bats` pins today's behaviour ("unset of a middle
element: bash leaves a hole that breaks peek and push"). Once fixed,
replace that test with this one. It fails today in bash and passes in zsh:

```bash
@test "unset of a middle element keeps peek and push working" {
  [ "$(test_shell_kind)" != "ash" ] || skip "the default layer has no ARRAY_unset"

  run in_test_shell 'ARRAY_define list
ARRAY_push list a; ARRAY_push list b; ARRAY_push list c
ARRAY_unset list 1
echo "count=$(ARRAY_count list) peek=$(ARRAY_peek list)"
ARRAY_push list d
echo "count=$(ARRAY_count list) peek=$(ARRAY_peek list)"'

  assert_status 0
  assert_output "$(printf 'count=2 peek=c\ncount=3 peek=d')"
}
```

The expected output is zsh's behaviour (later elements move down). Whether
that is the intended meaning of "unset" for this API is not decided.

## Proposal (input, not decided)

Re-pack the array after unsetting in bash (`list=("${list[@]}")`), which
gives zsh's behaviour. Not tried yet.

## Decision

_Not yet established._
