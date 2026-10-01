#!/usr/bin/env bats

# How colorize passes text through: plain text, joined arguments, whitespace,
# entities and backslash sequences.

load helpers/colorize

setup_file() {
  require_test_shell
}

@test "plain text is printed unchanged, with a newline" {
  run colorize_in_test_shell_showing_line_ends 'just some text'

  assert_status 0
  assert_output 'just some text$'
}

@test "an empty string prints an empty line" {
  run in_test_shell_showing_line_ends 'colorize ""'

  assert_status 0
  assert_output '$'
}

@test "no arguments print an empty line" {
  run in_test_shell_showing_line_ends 'colorize'

  assert_status 0
  assert_output '$'
}

@test "several arguments are joined with one space, inner whitespace kept" {
  run colorize_in_test_shell 'a' 'b  c' '<red>d</red>'

  assert_status 0
  assert_output 'a b  c ^[[0;31md^[[0m'
}

@test "leading and trailing whitespace is kept" {
  run colorize_in_test_shell_showing_line_ends '  padded  '

  assert_status 0
  assert_output '  padded  $'
}

@test "a newline inside the text is kept" {
  run colorize_in_test_shell_showing_line_ends "$(printf 'first\nsecond')"

  assert_status 0
  assert_output "$(printf 'first$\nsecond$')"
}

@test "text before, between and after tags is kept" {
  run colorize_in_test_shell 'before <red>one</red> between <blue>two</blue> after'

  assert_status 0
  assert_output 'before ^[[0;31mone^[[0m between ^[[0;34mtwo^[[0m after'
}

@test "percent signs are not a format" {
  run colorize_in_test_shell '<red>100%</red> %s %d'

  assert_status 0
  assert_output '^[[0;31m100%^[[0m %s %d'
}

@test "arguments are joined before parsing, so a tag can span them" {
  run colorize_in_test_shell '<red>a' 'b</red>'

  assert_status 0
  assert_output '^[[0;31ma b^[[0m'
}

@test "a tag can span a newline" {
  run colorize_in_test_shell "$(printf '<red>first\nsecond</red>')"

  assert_status 0
  assert_output "$(printf '^[[0;31mfirst\nsecond^[[0m')"
}

@test "&lt; and &gt; become < and >, outside and inside tags" {
  run colorize_in_test_shell '1 &lt; 2 <red>&gt;&gt;</red> &lt;&lt;'

  assert_status 0
  assert_output '1 < 2 ^[[0;31m>>^[[0m <<'
}

@test "an escaped tag is printed as text, not applied" {
  run colorize_in_test_shell '&lt;red&gt;not red&lt;/red&gt;'

  assert_status 0
  assert_output '<red>not red</red>'
}

@test "a lone > is printed as it is" {
  run colorize_in_test_shell 'a > b'

  assert_status 0
  assert_output 'a > b'
}

# Decoding &amp; is proposed in todo 01m3vfmxyb4fxzzgvq1wyw1jt0.
@test "&amp; is not decoded" {
  run colorize_in_test_shell '&amp; &amp;lt;'

  assert_status 0
  assert_output '&amp; &amp;lt;'
}

@test "backslash sequences \\n and \\t are interpreted" {
  run colorize_in_test_shell_showing_line_ends 'a\nb\tc'

  assert_status 0
  assert_output "$(printf 'a$\nb\tc$')"
}

@test "an escape sequence written in the text reaches the terminal" {
  run colorize_in_test_shell 'x\033[1my'

  assert_status 0
  assert_output 'x^[[1my'
}

# zsh interprets backslash sequences twice: bug todo
# 01m3vj6swnh7hhb76kzx9x91pe, which has the test for the fixed behaviour.
@test "an escaped backslash: one backslash, or a second interpretation in zsh" {
  run colorize_in_test_shell 'a\\b'

  assert_status 0
  case "$(test_shell_kind)" in
    zsh) assert_output 'a^H' ;;
    *) assert_output 'a\b' ;;
  esac
}

# The README's prompt example. Its bash prompt escapes go through `echo -e`:
# bash and ash leave `\u` without hex digits alone, zsh's echo turns it into
# a NUL byte (one interpretation is enough for that).
@test "the README's prompt example keeps its prompt escapes, except \\u in zsh" {
  run colorize_in_test_shell -p '<yellow>\@ \u@\h:\W</yellow> $ '

  assert_status 0
  case "$(test_shell_kind)" in
    zsh) assert_output '\[^[[0;33m\]\@ ^@@\h:\W\[^[[0m\] $ ' ;;
    *) assert_output '\[^[[0;33m\]\@ \u@\h:\W\[^[[0m\] $ ' ;;
  esac
}

# The same bug: in zsh the first interpretation cuts the text, the second
# prints the newline.
@test "\\c ends the output: without the newline, except in zsh" {
  run colorize_in_test_shell_showing_line_ends 'a\cb'

  assert_status 0
  case "$(test_shell_kind)" in
    zsh) assert_output 'a$' ;;
    *) assert_output 'a' ;;
  esac
}
