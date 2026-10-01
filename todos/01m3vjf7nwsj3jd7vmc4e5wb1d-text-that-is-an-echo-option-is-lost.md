# Bug: text that is an `echo` option is lost

**Priority:** bug

Text that consists only of an option `echo` knows (`-n`, `-e`, `-E`, or a
combination such as `-neE`) is lost, even after `--`: with `-n` in it
nothing is printed, not even the newline; `-e` and `-E` print an empty line.

```
colorize -- "-n"     # prints nothing instead of "-n"
colorize -- "-n x"   # prints "-n x": only text that is exactly an option is affected
```

Checked with bash 5.3.20, bash 3.2.57 and zsh 5.9.2. `--` keeps such text
away from colorize's own `getopts` (todo `01m3vfmxyb4fxzzgvq1wyw1jsx`), but
not away from `echo`.

## Cause

`colorize` prints the processed text with `echo -e` / `echo -en`, which
takes the text as its own option. (`COLORIZER_process_input` returns its
result with `printf '%s\n'`, which keeps it.)

## Test that detects it

`tests/options.bats` pins today's behaviour ("text that is an echo option
is lost, even after --"). Once fixed, replace that test with
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

Print with `printf '%b'` / `printf '%b\n'` instead of `echo -en` /
`echo -e` in `colorize`. `%b` interprets backslash sequences as `echo -e`
does. Tried on 2026-10-01, together with the `printf '%s\n'` in
`COLORIZER_process_input` that is now in place: the test above then passed
in bash 5.3.20, bash 3.2.57 and zsh 5.9.2.

Caveat: `%b` and `echo -e` are not identical. For `\u` without hex digits,
bash's `echo -e` prints `\u` silently, while bash's `printf '%b'` prints
it too but writes `missing unicode digit for \u` to stderr (bash 5.3.20).
The README's prompt example contains `\u` (`tests/text.bats`, "the README's
prompt example"), so with this change it would warn in bash.

## Decision

_Not yet established._
