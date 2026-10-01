# Bug: text that is an `echo` option is lost

**Priority:** bug

Text that consists only of an option `echo` knows (`-n`, `-e`, `-E`, or a
combination such as `-neE`) prints as an empty line, even after `--`:

```
colorize -- "-n"     # prints an empty line instead of "-n"
colorize -- "-n x"   # prints "-n x": only text that is exactly an option is affected
```

Checked with bash 5.3.20, bash 3.2.57 and zsh 5.9.2. `--` keeps such text
away from colorize's own `getopts` (todo `01m3vfmxyb4fxzzgvq1wyw1jsx`), but
not away from `echo`.

## Cause

`COLORIZER_process_input` returns its result with `echo "${result}"`
(`colorizer.sh:151`), which takes `-n` as its option and prints nothing.
`colorize` then prints that empty result with `echo -e` / `echo -en`
(lines 191 and 193), which would take the text as an option as well.

## Test that detects it

`tests/options.bats` pins today's behaviour ("text that is an echo option
prints an empty line, even after --"). Once fixed, replace that test with
this one. It fails today in all three shells above:

```bash
@test "text that is an echo option is printed after --" {
  local text
  for text in -n -e -E -neE; do
    run colorize_in_test_shell_showing_line_ends -- "${text}"

    assert_status 0
    assert_output "${text}\$"
  done
}
```

## Proposal (input, not decided)

Print with `printf` instead of `echo`:

- line 151: `printf '%s\n' "${result}"`
- line 191: `printf '%b' "${processed_message}"`
- line 193: `printf '%b\n' "${processed_message}"`

`%b` interprets backslash sequences as `echo -e` does. Tried on
2026-10-01 by patching the library temporarily: the test above then passes
in all three shells, and of the existing suite only the tests that pin
today's bugs change. In zsh that includes the two tests of bug
`01m3vj6swnh7hhb76kzx9x91pe` (backslashes interpreted twice), which this
change fixes as well. Not yet tried in busybox ash.

Caveat: `%b` and `echo -e` are not identical. For `\u` without hex digits,
bash's `echo -e` prints `\u` silently, while bash's `printf '%b'` prints
it too but writes `missing unicode digit for \u` to stderr (bash 5.3.20).
The README's prompt example contains `\u` (`tests/text.bats`, "the README's
prompt example"), so with this change it would warn in bash.

## Decision

_Not yet established._
