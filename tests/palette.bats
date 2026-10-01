#!/usr/bin/env bats

# The palette as an extension point: every COLORIZER_<name> variable is a
# tag, built-in entries can be overridden before or after loading, and the
# escape sequence's start and end are variables as well.

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "any COLORIZER_<name> variable is a tag" {
  run in_test_shell 'COLORIZER_title="1;3;4:2"; colorize "$1"' '<title>T</title>'

  assert_status 0
  assert_output '^[[1;3;4:2mT^[[0m'
}

@test "a dash in a custom tag maps to an underscore in its variable" {
  run in_test_shell 'COLORIZER_drift_header="1;34"; colorize "$1"' '<drift-header>H</drift-header>'

  assert_status 0
  assert_output '^[[1;34mH^[[0m'
}

@test "a custom tag nests like a built-in one" {
  run in_test_shell 'COLORIZER_note="2"; colorize "$1"' '<red>a<note>b</note>c</red>'

  assert_status 0
  assert_output '^[[0;31ma^[[2mb^[[0;31mc^[[0m'
}

@test "a built-in tag overridden after loading uses the new code" {
  run in_test_shell 'COLORIZER_red="1;35"; colorize "$1"' '<red>x</red>'

  assert_status 0
  assert_output '^[[1;35mx^[[0m'
}

@test "a built-in tag set before loading keeps its value" {
  export COLORIZER_red="1;36"

  run colorize_in_test_shell '<red>x</red>'

  assert_status 0
  assert_output '^[[1;36mx^[[0m'
}

# The defaults are assigned with `${VAR:=default}`, which treats an empty
# value like an unset one.
@test "a built-in tag set to empty before loading gets its default" {
  export COLORIZER_red=""

  run colorize_in_test_shell '<red>x</red>'

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

@test "magenta follows purple when purple is set before loading" {
  export COLORIZER_purple="9"

  run colorize_in_test_shell '<magenta>m</magenta>'

  assert_status 0
  assert_output '^[[9mm^[[0m'
}

@test "magenta keeps the default when purple is changed after loading" {
  run in_test_shell 'COLORIZER_purple="9"; colorize "$1"' '<purple>p</purple><magenta>m</magenta>'

  assert_status 0
  assert_output '^[[9mp^[[0m^[[0;35mm^[[0m'
}

@test "the reset after the outermost tag is COLORIZER_none" {
  run in_test_shell 'COLORIZER_none="0;49"; colorize "$1"' '<red>x</red>'

  assert_status 0
  assert_output '^[[0;31mx^[[0;49m'
}

@test "COLORIZER_START and COLORIZER_END frame every code" {
  run in_test_shell 'COLORIZER_START="[" COLORIZER_END="]"; colorize "$1"' '<red>x</red>'

  assert_status 0
  assert_output '[0;31]x[0]'
}

@test "palette changes in the calling script last for later calls" {
  run in_test_shell 'COLORIZER_red="1;35"; colorize "$1"; colorize "$1"' '<red>x</red>'

  assert_status 0
  assert_output "$(printf '^[[1;35mx^[[0m\n^[[1;35mx^[[0m')"
}
