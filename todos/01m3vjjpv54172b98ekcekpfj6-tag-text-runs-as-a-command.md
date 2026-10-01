# Bug (security): tag text runs as a shell command in zsh

**Priority:** bug, security

A command substitution inside a tag is executed:

```bash
colorize 'a<x:-$(touch /tmp/marker)>b</x:-$(touch /tmp/marker)>'   # creates /tmp/marker
```

Checked 2026-10-01 with a marker file, for the payloads `x:-$(touch …)`,
`x$(touch …)` and `` x`touch …` ``, after `ARRAY_push` stopped evaluating
its value:

| Shell | Runs the command |
|---|---|
| zsh 5.9.2 | yes, `x:-$(touch …)` |
| bash 5.3.20, bash 3.2.57, busybox ash | no |

Before that fix, bash and zsh ran all three payloads when pushing the tag
name onto the stack.

Any caller that passes text from outside the script through `colorize`
(command output, file contents, user input) lets that text run commands
with the caller's rights. The payload only needs to look like a tag: no
`>` and no `"` inside it.

## Cause

The palette lookup pastes the tag name into evaluated code:
`eval "ansiToken=\"\${COLORIZER_${pseudoTag}}\""`, after turning `-` into
`_`. For the tag `x:-$(touch …)` that is `${COLORIZER_x:_$(touch …)}`. zsh
evaluates the part after the `:` and runs the command substitution in it;
bash and ash do not run it.

## Test that detects it

`tests/errors.bats` pins today's behaviour ("a command substitution in tag
text runs in zsh"). Once fixed, replace that test with this one. It fails
today in zsh and passes in bash and ash:

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
- A smaller fix: validating tag names before the lookup
  (`01m3vjjpv54172b98ekcekpfj5`).

## Decision

_Not yet established._
