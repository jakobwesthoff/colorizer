#!/usr/bin/env bats

# Nested and adjacent tags. Closing a tag re-emits the code of the tag around
# it; built-in codes start with `0;`, so each code replaces the previous one
# instead of adding to it.

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "adjacent tags each end with the reset" {
  run colorize_in_test_shell '<red>a</red><blue>b</blue>'

  assert_status 0
  assert_output '^[[0;31ma^[[0m^[[0;34mb^[[0m'
}

@test "three levels restore each parent in turn" {
  run colorize_in_test_shell '<red>a<blue>b<green>c</green>d</blue>e</red>'

  assert_status 0
  assert_output '^[[0;31ma^[[0;34mb^[[0;32mc^[[0;34md^[[0;31me^[[0m'
}

@test "nested tags with nothing between them" {
  run colorize_in_test_shell '<red><blue><green>x</green></blue></red>'

  assert_status 0
  assert_output '^[[0;31m^[[0;34m^[[0;32mx^[[0;34m^[[0;31m^[[0m'
}

@test "the same tag nested in itself" {
  run colorize_in_test_shell '<red>a<red>b</red>c</red>'

  assert_status 0
  assert_output '^[[0;31ma^[[0;31mb^[[0;31mc^[[0m'
}

@test "an attribute inside a colour keeps the colour" {
  run in_test_shell 'COLORIZER_bold=1; colorize "$1"' '<red>a<bold>b</bold>c</red>'

  assert_status 0
  assert_output '^[[0;31ma^[[1mb^[[0;31mc^[[0m'
}

# Styles replace each other instead of combining; combining is proposed in
# todo 01m3vfmxyb4fxzzgvq1wyw1jt4.
@test "a colour inside an attribute drops the attribute, and keeps the colour after closing" {
  run in_test_shell 'COLORIZER_bold=1; colorize "$1"' '<bold>a<red>b</red>c</bold>'

  assert_status 0
  assert_output '^[[1ma^[[0;31mb^[[1mc^[[0m'
}

# Bug todo 01m3vfmxyb4fxzzgvq1wyw1jsw, which has the test for the fixed
# behaviour: the parent's name is looked up without turning `-` into `_`,
# which the shell reads as `${COLORIZER_light-red}`, "red" when
# COLORIZER_light is unset.
@test "closing a tag inside a dashed parent emits the rest of the parent's name" {
  run colorize_in_test_shell '<light-red>a<blue>b</blue>c</light-red>'

  assert_status 0
  assert_output '^[[1;31ma^[[0;34mb^[[redmc^[[0m'

  run colorize_in_test_shell '<bg-light-red>a<blue>b</blue>c</bg-light-red>'

  assert_status 0
  assert_output '^[[0;30;101ma^[[0;34mb^[[light-redmc^[[0m'
}

@test "a dashed tag inside a plain one is restored correctly" {
  run colorize_in_test_shell '<red>a<light-blue>b</light-blue>c</red>'

  assert_status 0
  assert_output '^[[0;31ma^[[1;34mb^[[0;31mc^[[0m'
}
