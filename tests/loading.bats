#!/usr/bin/env bats

# Loading the library the way the README tells users to: sourcing it from a
# script file, with or without COLORIZE_SH_SOURCE_DIR, under `set -u` and
# `set -e`, and what loading leaves behind.

load helpers/colorize

setup_file() {
  require_test_shell
}

###
# Run a script file in the shell under test
#
# Unlike in_test_shell, nothing is loaded for the script: it does that
# itself, as these tests are about loading. Scripts run from a file, not
# from `-c`, because aliases and `$0` behave differently there. The working
# directory is the test's temporary directory.
#
# Arguments:
#   body: the script, after the CPU-time limit every test shell gets
###
run_script_in_test_shell() {
  local script="${BATS_TEST_TMPDIR}/script"
  printf 'ulimit -t %s\n%s\n' "${TEST_CPU_SECONDS}" "${1}" > "${script}"

  (cd "${BATS_TEST_TMPDIR}" && "${TEST_SHELL}" ./script 2>&1) | cat -v
  return "${PIPESTATUS[0]}"
}

@test "COLORIZE_SH_SOURCE_DIR loads the library in every shell" {
  run run_script_in_test_shell "COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colorize '<red>x</red>'"

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

# The README: shells that set neither BASH_SOURCE nor $0 for a sourced file
# need COLORIZE_SH_SOURCE_DIR.
@test "without COLORIZE_SH_SOURCE_DIR, bash and zsh find the library; ash does not" {
  run run_script_in_test_shell ". '${LIBRARY_DIR}/colorizer.sh'
colorize '<red>x</red>'"

  case "$(test_shell_kind)" in
    ash)
      [[ "${output}" == *"Compatibility/compatibility.sh"*"No such file or directory"* ]]
      ;;
    *)
      assert_status 0
      assert_output '^[[0;31mx^[[0m'
      ;;
  esac
}

@test "a relative path from another directory loads the library" {
  mkdir "${BATS_TEST_TMPDIR}/elsewhere"
  cp -R "${LIBRARY_DIR}" "${BATS_TEST_TMPDIR}/elsewhere/Library"

  run run_script_in_test_shell "COLORIZE_SH_SOURCE_DIR='./elsewhere/Library'
. ./elsewhere/Library/colorizer.sh
colorize '<red>x</red>'"

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

@test "a library path with spaces loads the library" {
  mkdir "${BATS_TEST_TMPDIR}/with space"
  cp -R "${LIBRARY_DIR}" "${BATS_TEST_TMPDIR}/with space/Library"

  run run_script_in_test_shell "COLORIZE_SH_SOURCE_DIR='${BATS_TEST_TMPDIR}/with space/Library'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colorize '<red>x</red>'"

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

@test "loading twice keeps palette changes made in between" {
  run run_script_in_test_shell "COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
COLORIZER_red=1
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colorize '<red>x</red>'"

  assert_status 0
  assert_output '^[[1mx^[[0m'
}

@test "set -e in the calling script survives loading and use" {
  run run_script_in_test_shell "set -e
COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colorize '<red>x</red>'
echo after"

  assert_status 0
  assert_output "$(printf '^[[0;31mx^[[0m\nafter')"
}

@test "set -u after loading survives every option" {
  run run_script_in_test_shell "COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
set -u
colorize '<red>x</red>'
colorize -n -p '<red>x</red>'
echo
colorize -s '<red>x</red>'"

  assert_status 0
  assert_output "$(printf '^[[0;31mx^[[0m\n\\[^[[0;31m\\]x\\[^[[0m\\]\nx')"
}

# compatibility.sh tests BASH_VERSION and ZSH_VERSION, of which at least
# one is unset in every shell.
@test "set -u before loading works in every shell" {
  run run_script_in_test_shell "set -u
COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colorize '<red>x</red>'"

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

# Bug todo 01m3vjvakjz2b1z1rn3d13tqdc: bash does not expand aliases in
# scripts.
@test "the colourise alias: works in zsh and ash scripts, not in bash scripts" {
  local script="COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colourise '<red>x</red>'"

  case "$(test_shell_kind)" in
    bash)
      run -127 run_script_in_test_shell "${script}"
      [[ "${output}" == *"colourise: command not found"* ]]
      ;;
    *)
      run -0 run_script_in_test_shell "${script}"
      assert_output '^[[0;31mx^[[0m'
      ;;
  esac
}

@test "the colourise alias works in bash scripts that enable alias expansion" {
  run run_script_in_test_shell "shopt -s expand_aliases 2> /dev/null
COLORIZE_SH_SOURCE_DIR='${LIBRARY_DIR}'
. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"
colourise '<red>x</red>'"

  assert_status 0
  assert_output '^[[0;31mx^[[0m'
}

@test "colorize leaves none of its working variables behind" {
  run in_test_shell 'colorize "<red>x</red>" > /dev/null
echo "${stack-unset} ${stack_COUNT-unset} ${result-unset} ${processed-unset} ${pseudoTag-unset} ${ansiToken-unset} ${processed_message-unset} ${option-unset}"'

  assert_status 0
  assert_output 'unset unset unset unset unset unset unset unset'
}

@test "colorize keeps the caller's OPTIND" {
  run in_test_shell 'OPTIND=5; colorize -n "x" > /dev/null; echo "${OPTIND}"'

  assert_status 0
  assert_output '5'
}
