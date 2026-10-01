#!/usr/bin/env bats

# Malformed markup: mismatched, unclosed and stray tags, tag names that are
# not valid variable names, a `<` that never closes, and tag text that must
# never run as code.

load helpers/colorize

setup_file() {
  require_test_shell
}

###
# Run `colorize "$1"` in the shell under test, ended after a few seconds
#
# Prints the raw output (no `cat -v`), as the shell is started directly so
# that with_time_limit can end it. Status 124 means it was ended.
###
colorize_with_time_limit() {
  with_time_limit 3 "${TEST_SHELL}" -c "$(library_loader)
colorize \"\$1\"" colorizer-test "${1}"
}

# Malformed markup is reported on stderr with status 42; stdout gets the text
# with the tags removed, so captured output stays readable.
@test "a mismatched closing tag: message on stderr, the bare text, status 42" {
  run --separate-stderr colorize_in_test_shell '<red>x</green>'

  assert_status 42
  assert_output 'x'
  [ "${stderr}" = 'Mismatching colorize tag nesting at <red>...</green>' ]
}

@test "an unclosed tag: message on stderr, the bare text, status 42" {
  run --separate-stderr colorize_in_test_shell '<red><blue>x</blue>'

  assert_status 42
  assert_output 'x'
  [ "${stderr}" = 'Could not find closing tag for <red>' ]
}

@test "a closing tag without an opening one: message on stderr, the bare text, status 42" {
  run --separate-stderr colorize_in_test_shell 'x</red>'

  assert_status 42
  assert_output 'x'
  [ "${stderr}" = 'Mismatching colorize tag nesting at <>...</red>' ]
}

@test "the bare text keeps entities decoded and invalid tag names as text" {
  run --separate-stderr colorize_in_test_shell '<red>1 &lt; 2 <a b> <blue>c</blue>'

  assert_status 42
  assert_output '1 < 2 <a b> c'
}

@test "the bare text follows -n" {
  run --separate-stderr colorize_in_test_shell_showing_line_ends -n '<red>x'

  assert_status 42
  assert_output 'x'
}

# colorize returns the status instead of exiting, so a calling script, or an
# interactive shell that loaded the library, goes on.
@test "malformed markup does not end the calling script" {
  run --separate-stderr in_test_shell 'colorize "<red>x"; echo "colorize returned $?, still running"'

  assert_status 0
  assert_output "$(printf 'x\ncolorize returned 42, still running')"
}

@test "an empty tag is printed as text" {
  run colorize_in_test_shell '<>x</>'

  assert_status 0
  assert_output '<>x</>'
}

# Only names that can be part of a variable name are tags, so text between
# `<` and `>` never reaches the palette lookup's `eval` as code.
@test "a tag name that is not a variable name is printed as text" {
  run --separate-stderr colorize_in_test_shell '<red >x</red >'

  assert_status 0
  assert_output '<red >x</red >'
  [ -z "${stderr}" ]

  run --separate-stderr colorize_in_test_shell 'a < b > c <red>d</red>'

  assert_status 0
  assert_output 'a < b > c ^[[0;31md^[[0m'
  [ -z "${stderr}" ]
}

# Without a `>` after it, a `<` cannot start a tag; the rest of the text is
# printed as it is.
@test "a < with no > after it is printed as text" {
  run colorize_with_time_limit 'a<b'

  assert_status 0
  assert_output 'a<b'

  run --separate-stderr colorize_with_time_limit 'a < b'

  assert_status 0
  assert_output 'a < b'
  [ -z "${stderr}" ]

  run colorize_with_time_limit '<red>x</red> if 1 < 2'

  assert_status 0
  assert_output $'\e[0;31mx\e[0m if 1 < 2'
}

@test "tag text is never run as a command" {
  export MARKER="${BATS_TEST_TMPDIR}/ran"

  run colorize_in_test_shell 'a<x:-$(touch $MARKER)>b</x:-$(touch $MARKER)>'

  [ ! -e "${MARKER}" ]

  run colorize_in_test_shell 'a<x$(touch $MARKER)>b</x$(touch $MARKER)>'

  [ ! -e "${MARKER}" ]

  run colorize_in_test_shell 'a<x`touch $MARKER`>b</x`touch $MARKER`>'

  [ ! -e "${MARKER}" ]
}
