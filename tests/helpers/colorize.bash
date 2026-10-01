# Shared setup for the colorizer suite.
#
# bats runs the tests in bash, but colorizer has to work in every shell the
# README names. Each test therefore runs its code in a separate process of
# the shell under test, named by TEST_SHELL, and never sources the library
# into bats' own shell.
#
# The tests pin the library's current behaviour, including behaviour the todos
# in `todos/` want to change. Such tests say so and name the todo, so the
# commit that changes the behaviour also changes the expectation.

bats_require_minimum_version 1.5.0

LIBRARY_DIR="$(cd "${BATS_TEST_DIRNAME}/../Library" && pwd)"

###
# Fail the run when TEST_SHELL is unset or not installed, so a missing shell
# shows up as an error instead of a run against some other shell
###
require_test_shell() {
  if [ -z "${TEST_SHELL:-}" ]; then
    echo "TEST_SHELL is not set; run the suite through \`just test\`" >&2
    return 1
  fi

  if ! command -v "${TEST_SHELL}" > /dev/null; then
    echo "TEST_SHELL '${TEST_SHELL}' is not installed" >&2
    return 1
  fi
}

###
# The family of the shell under test: bash, zsh or ash
#
# For tests whose expectation differs between shells. TEST_SHELL may be a
# path, such as macOS's /bin/bash.
###
test_shell_kind() {
  case "${TEST_SHELL##*/}" in
    bash*) echo "bash" ;;
    zsh*) echo "zsh" ;;
    ash | busybox | sh) echo "ash" ;;
    *) echo "unknown" ;;
  esac
}

###
# The lines that load the library at the start of every script
#
# COLORIZE_SH_SOURCE_DIR is set for every shell: the compatibility layer's
# fallback for shells other than bash and zsh, which busybox ash takes, finds
# its files only through it. Loading without it is tested in loading.bats.
# The path is single-quoted, so it must not contain a single quote.
###
library_loader() {
  printf "COLORIZE_SH_SOURCE_DIR='%s'\n. \"\${COLORIZE_SH_SOURCE_DIR}/colorizer.sh\"\n" "${LIBRARY_DIR}"
}

###
# Run a script in the shell under test, after loading the library
#
# The script is appended to the loader as source text, not passed to `eval`,
# so the shell parses it as it would parse a script of its own. Further
# arguments become the script's positional parameters, which keeps test input
# free of quoting.
#
# stdout goes through `cat -v`, so escape codes read as `^[[0;31m` in
# assertions and in failure output. The status is the shell's, not cat's.
#
# Arguments:
#   script: shell code to run
#   ...: positional parameters for the script
###
in_test_shell() {
  local script="${1}"
  shift

  "${TEST_SHELL}" -c "$(library_loader)
${script}" colorizer-test "$@" | cat -v
  return "${PIPESTATUS[0]}"
}

###
# Like in_test_shell, but marks every line end with `$` (`cat -ve`)
#
# bats' `run` drops trailing newlines from the output; this keeps them
# visible, for the tests about newlines.
###
in_test_shell_showing_line_ends() {
  local script="${1}"
  shift

  "${TEST_SHELL}" -c "$(library_loader)
${script}" colorizer-test "$@" | cat -ve
  return "${PIPESTATUS[0]}"
}

###
# Run `colorize` with the given arguments in the shell under test
###
colorize_in_test_shell() {
  # shellcheck disable=SC2016 # expanded by the shell under test
  in_test_shell 'colorize "$@"' "$@"
}

###
# Run a command, and end it after the given number of seconds
#
# For inputs that make colorize loop forever. The command runs in the
# background and is polled, as macOS has no `timeout` command.
#
# The command must be an external program, not a function: a backgrounded
# simple command runs as that program's own process, so `kill` reaches it.
# A function would run in a subshell whose children survive the kill.
#
# Arguments:
#   seconds: how long the command may run
#   ...: the command
#
# Success: the command's status
# Error: 124 when it was ended, like coreutils' `timeout`
###
with_time_limit() {
  local seconds="${1}"
  shift

  "$@" &
  local pid="${!}"
  local polls=$((seconds * 10))

  while [ "${polls}" -gt 0 ]; do
    if ! kill -0 "${pid}" 2> /dev/null; then
      wait "${pid}"
      return "${?}"
    fi
    sleep 0.1
    polls=$((polls - 1))
  done

  kill "${pid}" 2> /dev/null
  wait "${pid}" 2> /dev/null
  return 124
}

###
# Compare $output with the expected text, and show both when they differ
###
assert_output() {
  # shellcheck disable=SC2154 # set by bats' `run`
  if [ "${output}" != "${1}" ]; then
    printf 'expected output: %s\nactual output:   %s\n' "${1}" "${output}"
    return 1
  fi
}

###
# Compare $status with the expected status, and show both when they differ
###
assert_status() {
  # shellcheck disable=SC2154 # set by bats' `run`
  if [ "${status}" -ne "${1}" ]; then
    printf 'expected status: %s\nactual status:   %s\noutput: %s\n' "${1}" "${status}" "${output}"
    return 1
  fi
}
