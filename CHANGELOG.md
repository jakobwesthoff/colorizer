# Changelog

## Unreleased

### Changed

- Malformed markup (a mismatched, unclosed or stray closing tag) is reported
  on stderr, the text is printed without its tags, and `colorize` returns 42.
  Before, the message replaced the text on stdout and the status was 0.
- An unknown option is reported on stderr and `colorize` returns 42. Before,
  the message went to stdout and `exit 42` ended the calling script, or an
  interactive shell that had loaded the library.
- Text between `<` and `>` that is not a tag name (letters, digits, `_` and
  `-`) is printed as it is, the empty `<>` included. Before, such names caused
  shell errors and lost the whole text, and `<>` acted as an undefined tag.
- A `<` with no `>` after it is printed as it is. Before, `colorize` never
  returned.
- `colorize` prints with `printf '%b'` instead of `echo -e`. Backslash
  sequences are interpreted as before; text that is exactly an `echo` option,
  such as `-n`, is now printed instead of lost.
- `colourise` is a function instead of an alias, so it also works in bash
  scripts.

### Fixed

- Tag text could run as a shell command in bash and zsh, for example the tag
  `x:-$(cmd)`.
- Closing a tag nested inside a tag with a `-` in its name (`light-*`,
  `bg-*`) did not restore that tag's colour.
- zsh interpreted backslash sequences twice.
- Loading the library under `set -u` failed in zsh and busybox ash.
- Compatibility layer: `ARRAY_push` and `ARRAY_set` evaluated the value
  instead of storing it; `ARRAY_count` ignored empty values in bash and zsh
  and failed under `set -u` for an undefined array in busybox ash;
  `ARRAY_peek` and `ARRAY_pop` failed on an empty array, ending the script in
  busybox ash; `ARRAY_unset` in bash left a gap that broke `ARRAY_peek` and
  `ARRAY_push`.

### Added

- Text attribute tags: `bold`, `dim`, `italic`, `underline`,
  `double-underline`, `reverse` and `strike`.
- Bright color tags (`bright-red`, … `bright-black`), which use the terminal's
  bright colors instead of bold.
- A test suite (bats, run through just) for bash, zsh and busybox ash, on the
  host and in Docker for bash 3.2, 4.4 and 5.2.
