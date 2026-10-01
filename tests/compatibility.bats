#!/usr/bin/env bats

# The ARRAY_* compatibility layer, which colorize uses for its tag stack and
# which callers can use as well. bash and zsh have their own layers; busybox
# ash gets the default one (Library/Compatibility/default), which has no
# ARRAY_get, ARRAY_set and ARRAY_unset.

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "push, count, peek and pop" {
  run in_test_shell 'ARRAY_define list
ARRAY_push list one
ARRAY_push list two
ARRAY_count list
ARRAY_peek list
ARRAY_pop list
ARRAY_count list
ARRAY_peek list'

  assert_status 0
  assert_output "$(printf '2\ntwo\ntwo\n1\none')"
}

@test "a new array is empty" {
  run in_test_shell 'ARRAY_define list; ARRAY_count list'

  assert_status 0
  assert_output '0'
}

@test "values with spaces, backslashes, semicolons and globs are stored as they are" {
  run in_test_shell 'ARRAY_define list
for value in "a b" "back\\slash" "semi;colon" "*"; do
  ARRAY_push list "${value}"
  ARRAY_peek list
done'

  assert_status 0
  assert_output "$(printf 'a b\nback\\slash\nsemi;colon\n*')"
}

# Bug todo 01m3vk1qb40aghhdk8ngs7yz5r: ARRAY_push evaluates the value; bash
# and zsh inside double quotes, the default layer inside single quotes.
@test "values with quotes or \$: expanded in bash and zsh, a syntax error for ' in ash" {
  export HOME="/home/colorizer-test"

  run in_test_shell 'ARRAY_define list
ARRAY_push list "say \"hi\""; ARRAY_peek list
ARRAY_push list "cost \$HOME"; ARRAY_peek list'

  assert_status 0
  case "$(test_shell_kind)" in
    ash) assert_output "$(printf 'say "hi"\ncost $HOME')" ;;
    *) assert_output "$(printf 'say hi\ncost /home/colorizer-test')" ;;
  esac

  run --separate-stderr in_test_shell 'ARRAY_define list; ARRAY_push list "it'"'"'s"; ARRAY_peek list'

  case "$(test_shell_kind)" in
    ash) [[ "${stderr}" == *"unterminated quoted string"* ]] ;;
    *) assert_output "it's" ;;
  esac
}

@test "an array that was never defined counts as empty under set -u" {
  run in_test_shell 'set -u; ARRAY_count never_defined'

  assert_status 0
  assert_output '0'
}

@test "count includes empty values" {
  run in_test_shell 'ARRAY_define list; ARRAY_push list ""; ARRAY_count list
ARRAY_push list "two"; ARRAY_count list'

  assert_status 0
  assert_output "$(printf '1\n2')"
}

@test "peek and pop on an empty array print nothing and report no error" {
  run --separate-stderr in_test_shell 'ARRAY_define list
echo "peek: [$(ARRAY_peek list)]"
echo "pop: [$(ARRAY_pop list)]"
echo "count: $(ARRAY_count list)"'

  assert_output "$(printf 'peek: []\npop: []\ncount: 0')"
  [ -z "${stderr}" ]

  run in_test_shell 'ARRAY_define list
ARRAY_pop list > /dev/null
echo "still running, count $(ARRAY_count list)"'

  assert_status 0
  assert_output 'still running, count 0'
}

@test "the default layer has no ARRAY_get, ARRAY_set and ARRAY_unset" {
  run in_test_shell 'for f in ARRAY_get ARRAY_set ARRAY_unset; do
  command -v "${f}" > /dev/null && echo "${f}: defined" || echo "${f}: missing"
done'

  assert_status 0
  case "$(test_shell_kind)" in
    ash) assert_output "$(printf 'ARRAY_get: missing\nARRAY_set: missing\nARRAY_unset: missing')" ;;
    *) assert_output "$(printf 'ARRAY_get: defined\nARRAY_set: defined\nARRAY_unset: defined')" ;;
  esac
}

@test "get and set use zero-based indexes, in bash and zsh" {
  [ "$(test_shell_kind)" != "ash" ] || skip "the default layer has no ARRAY_get and ARRAY_set"

  run in_test_shell 'ARRAY_define list
ARRAY_push list a; ARRAY_push list b
ARRAY_get list 0; ARRAY_get list 1
ARRAY_set list 0 z
ARRAY_get list 0; ARRAY_count list'

  assert_status 0
  assert_output "$(printf 'a\nb\nz\n2')"
}

@test "unset of the last element shortens the array, in bash and zsh" {
  [ "$(test_shell_kind)" != "ash" ] || skip "the default layer has no ARRAY_unset"

  run in_test_shell 'ARRAY_define list
ARRAY_push list a; ARRAY_push list b
ARRAY_unset list 1
ARRAY_count list; ARRAY_peek list'

  assert_status 0
  assert_output "$(printf '1\na')"
}

# Bug todo 01m3vk1qb40aghhdk8ngs7yz5v: bash leaves a hole that peek and push
# do not expect; zsh moves the later elements down.
@test "unset of a middle element: bash leaves a hole that breaks peek and push" {
  [ "$(test_shell_kind)" != "ash" ] || skip "the default layer has no ARRAY_unset"

  run in_test_shell 'ARRAY_define list
ARRAY_push list a; ARRAY_push list b; ARRAY_push list c
ARRAY_unset list 1
echo "count=$(ARRAY_count list) peek=$(ARRAY_peek list)"
ARRAY_push list d
echo "count=$(ARRAY_count list) peek=$(ARRAY_peek list)"'

  assert_status 0
  case "$(test_shell_kind)" in
    bash) assert_output "$(printf 'count=2 peek=\ncount=2 peek=')" ;;
    zsh) assert_output "$(printf 'count=2 peek=c\ncount=3 peek=d')" ;;
  esac
}
