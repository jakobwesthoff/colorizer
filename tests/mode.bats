#!/usr/bin/env bats

# The colour mode: COLORIZER_MODE (always, never, auto) and colorize_detect.
# auto decides when the library is loaded, or when colorize_detect runs, not
# in every call, as callers run colorize inside `$(...)`, where stdout is
# never a terminal.

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "without a mode, colours are always on, also in a pipe and with NO_COLOR" {
  export NO_COLOR=1

  run colorize_in_test_shell '<red>x</red>'

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

@test "never strips the tags and gives empty codes" {
  export COLORIZER_MODE=never

  run in_test_shell_showing_line_ends 'colorize "<red>x</red>"; colorize -p "<red>y</red>"
colorize_code red; colorize_code -v code bold; printf "[%s]" "${code}"'

  assert_status 0
  assert_output "$(printf 'x$\ny$\n[]')"
}

@test "never set after loading applies from the next call on" {
  run colorize_in_test_shell_showing_line_ends '<red>x</red>'

  assert_output '^[[0;31mx^[[0m$'

  run in_test_shell 'COLORIZER_MODE=never; colorize "$1"' '<red>x</red>'

  assert_status 0
  assert_output 'x'
}

@test "auto loaded with stdout in a pipe gives no colours" {
  export COLORIZER_MODE=auto

  run colorize_in_test_shell '<red>x</red>'

  assert_status 0
  assert_output 'x'
}

@test "auto loaded on a terminal colours, also inside \$(...)" {
  export COLORIZER_MODE=auto

  run in_test_shell_on_a_terminal 'line="$(colorize "<red>x</red>")"; printf "%s" "${line}" > "${RESULT}"
code="$(colorize_code bold)"; printf " %s" "${code}" >> "${RESULT}"'

  assert_output '^[[0;31mx^[[0m ^[[1m'
}

@test "auto gives no colours on a terminal when NO_COLOR is set" {
  export COLORIZER_MODE=auto NO_COLOR=1

  run in_test_shell_on_a_terminal 'colorize "<red>x</red>" > "${RESULT}"'

  assert_output 'x'
}

@test "auto colours on a terminal when NO_COLOR is empty" {
  export COLORIZER_MODE=auto NO_COLOR=

  run in_test_shell_on_a_terminal 'colorize "<red>x</red>" > "${RESULT}"'

  assert_output '^[[0;31mx^[[0m'
}

@test "auto gives no colours on a dumb terminal" {
  export COLORIZER_MODE=auto TERMINAL_TYPE=dumb

  run in_test_shell_on_a_terminal 'colorize "<red>x</red>" > "${RESULT}"'

  assert_output 'x'
}

@test "never gives no colours on a terminal" {
  export COLORIZER_MODE=never

  run in_test_shell_on_a_terminal 'colorize "<red>x</red>" > "${RESULT}"'

  assert_output 'x'
}

@test "colorize_detect decides again, for stdout as it is then" {
  export COLORIZER_MODE=auto

  run in_test_shell_on_a_terminal 'exec > "${RESULT}"
colorize "<red>x</red>"
colorize_detect
colorize "<red>y</red>"'

  assert_output "$(printf '^[[0;31mx^[[0m\ny')"
}

@test "colorize_detect 2 decides for stderr" {
  export COLORIZER_MODE=auto

  run in_test_shell_on_a_terminal 'exec > "${RESULT}"
colorize_detect
colorize "<red>x</red>"
colorize_detect 2
colorize "<red>y</red>"'

  assert_output "$(printf 'x\n^[[0;31my^[[0m')"
}

@test "colorize_detect after setting auto picks the mode up" {
  run colorize_in_test_shell '<red>x</red>'

  assert_output '^[[0;31mx^[[0m'

  run in_test_shell 'COLORIZER_MODE=auto; colorize_detect; colorize "$1"' '<red>x</red>'

  assert_status 0
  assert_output 'x'
}

@test "colorize_detect rejects a file descriptor that is not a number" {
  run --separate-stderr in_test_shell 'colorize_detect x'

  assert_status 1
  assert_stderr 'Invalid file descriptor for colorize_detect: x'
}

@test "an unknown mode is reported by colorize_detect and colours stay on" {
  run --separate-stderr in_test_shell 'COLORIZER_MODE=sometimes; colorize_detect; echo "status $?"; colorize "<red>x</red>"'

  assert_output "$(printf 'status 1\n^[[0;31mx^[[0m')"
  assert_stderr 'Unknown COLORIZER_MODE: sometimes'
}
