# Bug: `ARRAY_count` reports 0 for arrays with empty values

**Priority:** bug

| Pushed | bash 5.3.20, 3.2.57 | zsh 5.9.2 | busybox ash |
|---|---|---|---|
| `""` | 0 | 0 | 1 |
| `""`, `two` | 0 | 2 | 2 |
| `a` (`ARRAY_set` at index 3 on an empty array) | 0 | 4 | n/a |

bash counts 0 whenever the first element is empty, zsh whenever all
elements are empty. The default layer (ash) keeps its own counter and is
right.

colorize pushes an empty name for the empty tag `<>`; `tests/errors.bats`
("an empty tag works like an undefined one") shows that `<>x</>` still
works.

## Cause

The bash and zsh `ARRAY_count` first test whether the array expands to an
empty string, `[ -z "$(set +u; eval "echo \"\${${name}}\"")" ]`, and
return 0 if so. In bash `${list}` is the first element, in zsh all elements
joined with spaces. The `set +u` was added in f661969 for arrays that are
unset under `set -u`.

## Test that detects it

`tests/compatibility.bats` pins today's behaviour ("counting empty values:
wrong in bash and zsh"). Once fixed, replace that test with this one. It
fails today in bash and zsh and passes in ash:

```bash
@test "count includes empty values" {
  run in_test_shell 'ARRAY_define list; ARRAY_push list ""; ARRAY_count list
ARRAY_push list "two"; ARRAY_count list'

  assert_status 0
  assert_output "$(printf '1\n2')"
}
```

## Proposal (input, not decided)

Count with `${#list[@]}` alone, guarded for unset arrays under `set -u`
(for example `${#list[@]}` inside `set +u` as today, without the emptiness
test). Not tried yet; `tests/loading.bats` covers `set -u`.

## Decision

_Not yet established._
