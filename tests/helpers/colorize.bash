# Shared setup for the colorizer suite.
#
# bats runs the tests in bash, but colorizer has to work in every shell the
# README names. Each test therefore runs `colorize` in a separate process of
# the shell under test, named by TEST_SHELL, and never sources the library
# into bats' own shell.

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
# Run `colorize` with the given arguments in the shell under test
#
# The output goes through `cat -v`, so escape codes read as `^[[0;31m` in
# assertions and in failure output. The status is colorize's, not cat's.
#
# COLORIZE_SH_SOURCE_DIR is set for every shell: the compatibility layer's
# fallback for shells other than bash and zsh, which busybox ash takes, finds
# its files only through it.
#
# TODO: Test loading without COLORIZE_SH_SOURCE_DIR in bash and zsh, the way
# the README tells users to load the library.
###
colorize_in_test_shell() {
  # shellcheck disable=SC2016 # expanded by the shell under test
  "${TEST_SHELL}" -c 'COLORIZE_SH_SOURCE_DIR="${1}"; . "${1}/colorizer.sh"; shift; colorize "$@"' \
    colorizer-test "${LIBRARY_DIR}" "$@" | cat -v
  return "${PIPESTATUS[0]}"
}
