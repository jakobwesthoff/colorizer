#!/usr/bin/env bats

# Every built-in tag and the code it produces: the tables in the README, plus
# the `magenta` aliases of the `purple` tags.

load helpers/colorize

setup_file() {
  require_test_shell
}

###
# Assert that a tag wraps text in its code, followed by the reset
###
assert_tag_code() {
  local tag="${1}"
  local code="${2}"

  run colorize_in_test_shell "<${tag}>text</${tag}>"

  assert_status 0
  assert_output "^[[${code}mtext^[[0m"
}

@test "foreground tags" {
  assert_tag_code red "0;31"
  assert_tag_code green "0;32"
  assert_tag_code yellow "0;33"
  assert_tag_code blue "0;34"
  assert_tag_code purple "0;35"
  assert_tag_code cyan "0;36"
}

@test "light foreground tags are bold plus the normal colour" {
  assert_tag_code light-red "1;31"
  assert_tag_code light-green "1;32"
  assert_tag_code light-yellow "1;33"
  assert_tag_code light-blue "1;34"
  assert_tag_code light-purple "1;35"
  assert_tag_code light-cyan "1;36"
}

@test "grey, black, white and none" {
  assert_tag_code gray "1;30"
  assert_tag_code light-gray "0;37"
  assert_tag_code black "0;30"
  assert_tag_code white "1;37"
  assert_tag_code none "0"
}

@test "background tags set a readable foreground as well" {
  assert_tag_code bg-red "0;37;41"
  assert_tag_code bg-green "0;30;42"
  assert_tag_code bg-yellow "0;30;43"
  assert_tag_code bg-blue "0;37;44"
  assert_tag_code bg-purple "0;37;45"
  assert_tag_code bg-cyan "0;30;46"
  assert_tag_code bg-gray "0;37;47"
  assert_tag_code bg-black "0;37;40"
  assert_tag_code bg-white "0;30;107"
}

@test "light background tags use the bright background colours" {
  assert_tag_code bg-light-red "0;30;101"
  assert_tag_code bg-light-green "0;30;102"
  assert_tag_code bg-light-yellow "0;30;103"
  assert_tag_code bg-light-blue "0;30;104"
  assert_tag_code bg-light-purple "0;30;105"
  assert_tag_code bg-light-cyan "0;30;106"
  assert_tag_code bg-light-gray "0;30;47"
}

@test "magenta tags are aliases of the purple tags" {
  assert_tag_code magenta "0;35"
  assert_tag_code light-magenta "1;35"
  assert_tag_code bg-magenta "0;37;45"
  assert_tag_code bg-light-magenta "0;30;105"
}

@test "an undefined tag produces an empty code, which resets" {
  assert_tag_code frobnicate ""
}

@test "tag names are case sensitive" {
  assert_tag_code RED ""
}
