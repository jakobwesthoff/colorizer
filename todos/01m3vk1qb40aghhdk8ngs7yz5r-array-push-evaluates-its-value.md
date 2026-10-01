# Bug: `ARRAY_push` evaluates the value instead of storing it

**Priority:** bug (security impact through colorize, see below)

`ARRAY_push list "$value"` does not store `$value` as given. Checked on
2026-10-01:

| Value | bash 5.3.20, 3.2.57, zsh 5.9.2 | busybox ash (default layer) |
|---|---|---|
| `say "hi"` | `say hi` | `say "hi"` |
| `cost $HOME` | `cost /home/...` (expanded) | `cost $HOME` |
| `it's` | `it's` | syntax error: `unterminated quoted string` |
| `$(cmd)` | runs `cmd` | stored as is |

Spaces, backslashes, `;` and `*` are stored correctly in all four shells.

colorize pushes every tag name onto its stack, so in bash and zsh tag text
from untrusted input runs commands: bug `01m3vjjpv54172b98ekcekpfj6`.

## Cause

The layers assign through `eval` with the value pasted into the code:

- bash and zsh: `eval "${name}[...]=\"${value}\""` (`ARRAY_push`;
  `ARRAY_set` the same), so the value is expanded inside double quotes.
- default layer: `eval "${name}_${index}='${value}'"`, so a `'` in the value
  ends the quoting.

## Test that detects it

`tests/compatibility.bats` pins today's behaviour ("values with quotes or
$: expanded in bash and zsh, a syntax error for ' in ash"). Once fixed,
replace that test with this one. It fails today in all four shells:

```bash
@test "push stores every value as it is given" {
  export HOME="/home/colorizer-test"

  run in_test_shell 'ARRAY_define list
for value in "say \"hi\"" "cost \$HOME" "it'"'"'s" "\$(echo ran)"; do
  ARRAY_push list "${value}"
  ARRAY_peek list
done'

  assert_status 0
  assert_output "$(printf '%s\n' 'say "hi"' 'cost $HOME' "it's" '$(echo ran)')"
}
```

## Proposal (input, not decided)

Keep the value out of the evaluated code: evaluate only the target and
reference the value by name, for example
`eval "${name}[\${#${name}[@]}]=\"\${value}\""` (the value is then
expanded once, from the local variable, not parsed as code). The same for
`ARRAY_set` and for the default layer. Not tried yet.

## Decision

_Not yet established._
