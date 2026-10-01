# Bug (security): tag text runs as a shell command in bash and zsh

**Priority:** bug, security

A command substitution inside a tag is executed:

```bash
colorize 'a<x:-$(touch /tmp/marker)>b</x:-$(touch /tmp/marker)>'   # creates /tmp/marker
```

Checked 2026-10-01 with a marker file, for the payloads `x:-$(touch …)`,
`x$(touch …)` and `` x`touch …` ``:

| Shell | Runs the command |
|---|---|
| bash 5.3.20, bash 3.2.57 | yes, all three |
| zsh 5.9.2 | yes, all three |
| busybox ash | no |

Any caller that passes text from outside the script through `colorize`
(command output, file contents, user input) lets that text run commands
with the caller's rights. The payload only needs to look like a tag: no
`>` and no `"` inside it.

## Cause

The bash and zsh compatibility layers push the tag name onto the stack
with `eval "${name}[...]=\"${value}\""` (`ARRAY_push` in
`Library/Compatibility/bash/array.bash` and `zsh/array.zsh`), so the value
is expanded inside double quotes, command substitutions included. The
default layer, which ash uses, quotes the value with single quotes
(`eval "${name}_${index}='${value}'"`), which is why ash is not affected
by these payloads. The palette lookups on `colorizer.sh:118` and 124 also
pass the tag name through `eval`; whether they run a payload on their own
was not isolated.

## Test that detects it

`tests/errors.bats` pins today's behaviour ("a command substitution in tag
text runs in bash and zsh"). Once fixed, replace that test with this one.
It fails today in bash and zsh and passes in ash:

```bash
@test "tag text is never run as a command" {
  export MARKER="${BATS_TEST_TMPDIR}/ran"

  run colorize_in_test_shell 'a<x:-$(touch $MARKER)>b</x:-$(touch $MARKER)>'

  [ ! -e "${MARKER}" ]

  run colorize_in_test_shell 'a<x$(touch $MARKER)>b</x$(touch $MARKER)>'

  [ ! -e "${MARKER}" ]

  run colorize_in_test_shell 'a<x`touch $MARKER`>b</x`touch $MARKER`>'

  [ ! -e "${MARKER}" ]
}
```

## Related

- Escaping untrusted text before calling `colorize` avoids it for callers
  who escape: `01m3vfmxyb4fxzzgvq1wyw1jt0`.
- The parser rewrite removes `eval` on input: `01m3vfmxyb4fxzzgvq1wyw1jt5`.
- A smaller fix: push without `eval` (`printf -v` in bash, `typeset` in
  zsh) or quote like the default layer, plus validating tag names
  (`01m3vjjpv54172b98ekcekpfj5`).

## Decision

_Not yet established._
