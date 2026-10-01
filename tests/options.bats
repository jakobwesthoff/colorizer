#!/usr/bin/env bats

# colorize's options -n, -p and -s, how getopts parses them, and what happens
# to text that looks like an option.

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "-n omits the newline" {
  run colorize_in_test_shell_showing_line_ends -n '<red>x</red>'

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

@test "-p wraps every code in \\[ and \\] for prompts" {
  run colorize_in_test_shell -p '<red>x</red>'

  assert_status 0
  assert_output '\[^[[0;31m\]x\[^[[0m\]'
}

@test "-p wraps the codes of nested tags as well" {
  run colorize_in_test_shell -p '<red>a<blue>b</blue></red>'

  assert_status 0
  assert_output '\[^[[0;31m\]a\[^[[0;34m\]b\[^[[0;31m\]\[^[[0m\]'
}

@test "-s strips the tags and still decodes entities" {
  run colorize_in_test_shell -s '<red>x</red> &lt;y&gt; <frobnicate>z</frobnicate>'

  assert_status 0
  assert_output 'x <y> z'
}

@test "-s still checks the nesting" {
  run colorize_in_test_shell -s '<red>x</green>'

  assert_status 42
  assert_output 'Mismatching colorize tag nesting at <red>...</green>'
}

@test "-s wins over -p" {
  run colorize_in_test_shell -ps '<red>x</red>'

  assert_status 0
  assert_output 'x'
}

@test "options combine, separately or in one word" {
  run colorize_in_test_shell_showing_line_ends -n -p '<red>x</red>'

  assert_status 0
  assert_output '\[^[[0;31m\]x\[^[[0m\]'

  run colorize_in_test_shell_showing_line_ends -np '<red>x</red>'

  assert_status 0
  assert_output '\[^[[0;31m\]x\[^[[0m\]'
}

@test "repeating an option has no further effect" {
  run colorize_in_test_shell_showing_line_ends -n -n 'x'

  assert_status 0
  assert_output 'x'
}

@test "options after the text are text" {
  run colorize_in_test_shell 'x' -n

  assert_status 0
  assert_output 'x -n'
}

@test "-- ends the options" {
  run colorize_in_test_shell -- '-x is text'

  assert_status 0
  assert_output '-x is text'
}

# Documented in todo 01m3vfmxyb4fxzzgvq1wyw1jsx: text needs `--` before it.
@test "text that is an option is taken as one" {
  run colorize_in_test_shell_showing_line_ends '-n'

  assert_status 0
  assert_output ''
}

@test "text that is an echo option is printed after --" {
  local text
  for text in -n -e -E -neE; do
    run colorize_in_test_shell_showing_line_ends -- "${text}"

    assert_status 0
    assert_output "${text}\$"
  done
}

@test "an invalid option prints a message and ends the calling script with 42" {
  run in_test_shell 'colorize -x "y"; echo "still running"'

  assert_status 42
  assert_output 'Invalid option (-x) given to colorize'
}

@test "an invalid option inside a group of options is found as well" {
  run in_test_shell 'colorize -nx "y"; echo "still running"'

  assert_status 42
  assert_output 'Invalid option (-x) given to colorize'
}
