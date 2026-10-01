#!/usr/bin/env bats

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "a nested tag restores the parent colour when it closes" {
  run colorize_in_test_shell '<red>a<blue>b</blue>c</red>'

  [ "${status}" -eq 0 ]
  [ "${output}" = '^[[0;31ma^[[0;34mb^[[0;31mc^[[0m' ]
}
