#!/usr/bin/env bats

# colorize_code: the escape sequence of one or more tags, for programs that
# render text themselves and only need the codes.

load helpers/colorize

setup_file() {
  require_test_shell
}

###
# Run `colorize_code` with the given arguments in the shell under test
###
colorize_code_in_test_shell() {
  in_test_shell_showing_line_ends 'colorize_code "$@"' "$@"
}

@test "the code of one tag, without a newline" {
  run colorize_code_in_test_shell red

  assert_status 0
  assert_output '^[[0;31m'
}

@test "several tags combine into one sequence" {
  run colorize_code_in_test_shell bold italic double-underline

  assert_status 0
  assert_output '^[[1;3;4:2m'
}

@test "a later tag drops its leading reset, so it adds to the earlier ones" {
  run colorize_code_in_test_shell bold red

  assert_status 0
  assert_output '^[[1;31m'

  run colorize_code_in_test_shell bold bg-red

  assert_status 0
  assert_output '^[[1;37;41m'
}

@test "the first tag keeps its leading reset" {
  run colorize_code_in_test_shell red bold

  assert_status 0
  assert_output '^[[0;31;1m'
}

@test "none gives the reset" {
  run colorize_code_in_test_shell none

  assert_status 0
  assert_output '^[[0m'
}

@test "custom tags work, a dash mapping to an underscore" {
  run in_test_shell_showing_line_ends 'COLORIZER_drift_header="1;34"; colorize_code drift-header'

  assert_status 0
  assert_output '^[[1;34m'
}

@test "COLORIZER_START and COLORIZER_END frame the sequence" {
  run in_test_shell_showing_line_ends 'COLORIZER_START="[" COLORIZER_END="]"; colorize_code red'

  assert_status 0
  assert_output '[0;31]'
}

@test "-v assigns the sequence to a variable and prints nothing" {
  run in_test_shell_showing_line_ends 'colorize_code -v code bold red; printf "status %s, %s" "$?" "${code}"'

  assert_status 0
  assert_output 'status 0, ^[[1;31m'
}

@test "an undefined tag is an error and prints nothing" {
  run --separate-stderr colorize_code_in_test_shell bold frobnicate

  assert_status 1
  assert_output ''
  assert_stderr 'Unknown colorize tag <frobnicate>'
}

@test "an invalid tag name is an error and is never evaluated" {
  export MARKER="${BATS_TEST_TMPDIR}/ran"

  run --separate-stderr colorize_code_in_test_shell 'x:-$(touch $MARKER)'

  assert_status 1
  assert_output ''
  assert_stderr 'Invalid colorize tag name <x:-$(touch $MARKER)>'
  [ ! -e "${MARKER}" ]
}

@test "no tag is an error" {
  run --separate-stderr colorize_code_in_test_shell

  assert_status 1
  assert_output ''
  assert_stderr 'colorize_code needs at least one tag'
}

@test "an invalid variable name for -v is an error and is never evaluated" {
  export MARKER="${BATS_TEST_TMPDIR}/ran"

  run --separate-stderr colorize_code_in_test_shell -v 'x;touch $MARKER' red

  assert_status 1
  assert_output ''
  assert_stderr 'Invalid variable name for colorize_code -v: x;touch $MARKER'
  [ ! -e "${MARKER}" ]
}

@test "an invalid option is reported on stderr with status 42" {
  run --separate-stderr colorize_code_in_test_shell -x red

  assert_status 42
  assert_output ''
  assert_stderr 'Invalid option (-x) given to colorize_code'
}

@test "-v without a variable name is reported on stderr with status 42" {
  run --separate-stderr colorize_code_in_test_shell -v

  assert_status 42
  assert_output ''
  assert_stderr 'Option -v of colorize_code needs a variable name'
}
