#!/usr/bin/env bats

# Malformed markup: mismatched, unclosed and stray tags, tag names that are
# not valid variable names, a `<` that never closes, and tag text that the
# library evaluates. Most of these are bugs; each test names its todo, which
# has the test for the fixed behaviour.

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

# Bug todo 01m3vjjpv54172b98ekcekpfj2: the README promises exit code 42.
@test "a mismatched closing tag replaces the output with a message, status 0" {
  run colorize_in_test_shell '<red>x</green>'

  assert_status 0
  assert_output 'Mismatching colorize tag nesting at <red>...</green>'
}

# Bug todo 01m3vjjpv54172b98ekcekpfj2.
@test "an unclosed tag replaces the output with a message, status 0" {
  run colorize_in_test_shell '<red><blue>x</blue>'

  assert_status 0
  assert_output 'Could not find closing tag for <red>'
}

# Bug todo 01m3vjjpv54172b98ekcekpfj2: the calling script goes on.
@test "malformed markup does not end the calling script" {
  run in_test_shell 'colorize "<red>x"; echo "still running"'

  assert_status 0
  assert_output "$(printf 'Could not find closing tag for <red>\nstill running')"
}

# Bug todo 01m3vjjpv54172b98ekcekpfj3: the empty stack is read as an element.
@test "a closing tag without an opening one: the message differs per shell" {
  run --separate-stderr colorize_in_test_shell 'x</red>'

  assert_status 0
  case "$(test_shell_kind)" in
    bash)
      assert_output 'Mismatching colorize tag nesting at <>...</red>'
      [[ "${stderr}" == *"bad array subscript"* ]]
      ;;
    zsh)
      assert_output 'Mismatching colorize tag nesting at <>...</red>'
      [ -z "${stderr}" ]
      ;;
    ash)
      assert_output 'Mismatching colorize tag nesting at <1>...</red>'
      ;;
  esac
}

@test "an empty tag works like an undefined one" {
  run colorize_in_test_shell '<>x</>'

  assert_status 0
  assert_output '^[[mx^[[0m'
}

# Bug todo 01m3vjjpv54172b98ekcekpfj5: the tag name is pasted into
# `${COLORIZER_...}`, where a space is a syntax error.
@test "a tag name with a space: no output in bash and ash, a reset in zsh" {
  run --separate-stderr colorize_in_test_shell '<red >x</red >'

  assert_status 0
  [[ "${stderr}" == *"bad substitution"* ]]
  case "$(test_shell_kind)" in
    zsh) assert_output '^[[mx^[[0m' ;;
    *) assert_output '' ;;
  esac
}

# Bug todo 01m3vjjpv54172b98ekcekpfj4: without a `>` after it, the parser
# never moves past the `<`.
@test "a < with no > after it loops forever" {
  run colorize_with_time_limit 'a<b'

  assert_status 124
}

# Bug todos 01m3vjjpv54172b98ekcekpfj4 and 01m3vjjpv54172b98ekcekpfj5: in
# bash and ash the syntax error ends the parser's subshell before it loops;
# zsh reports the error and goes on looping.
@test "a < followed by a space: an empty line in bash and ash, a loop in zsh" {
  run --separate-stderr colorize_with_time_limit 'a < b'

  case "$(test_shell_kind)" in
    zsh)
      assert_status 124
      ;;
    *)
      assert_status 0
      assert_output ''
      [[ "${stderr}" == *"bad substitution"* ]]
      ;;
  esac
}

# Bug todo 01m3vjjpv54172b98ekcekpfj6: bash and zsh `eval` the tag text when
# pushing it onto the stack; ash's compatibility layer quotes it.
@test "a command substitution in tag text runs in bash and zsh" {
  export MARKER="${BATS_TEST_TMPDIR}/ran"

  run --separate-stderr colorize_in_test_shell 'a<x:-$(touch $MARKER)>b</x:-$(touch $MARKER)>'

  case "$(test_shell_kind)" in
    ash) [ ! -e "${MARKER}" ] ;;
    *) [ -e "${MARKER}" ] ;;
  esac
}
