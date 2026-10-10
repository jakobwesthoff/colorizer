---
title: "Check zsh versions below 5.9 for support"
kind: investigation
component: library
horizon: someday
tags: [compatibility]
---
# Check zsh versions below 5.9 for support

The test suite pins colorizer's current output: 90 tests in `tests/`, run on the host and in Docker by `.github/workflows/tests.yml` through `just lint` and `just test-docker`. The open question is whether zsh older than 5.9 works, since the README claims zsh (>5.x) and only 5.9.2 has been checked. The parser rewrite must keep output byte for byte, so the suite is the check for any version that is tried.

## Revisit when

No trigger known; reconsider at the next sweep.

## Shells

The README claims bash (>3.x), zsh (>5.x) and busybox ash. Checked on 2026-10-01, sourcing `Library/colorizer.sh` and running `colorize '<red>a<blue>b</blue>c</red>'`:

| Shell | Result |
|---|---|
| bash 5.3.20 (Homebrew), bash 3.2.57 (macOS `/bin/bash`) | works |
| zsh 5.9.2 | works |
| busybox ash, `busybox:musl` image (needs `COLORIZE_SH_SOURCE_DIR`) | works |
| dash | fails: `source: not found`, then `Bad substitution`. Not claimed by the README. |

Docker images that provide these shells, checked on 2026-10-01 on arm64: the official `bash` image has tags per bash version (`bash:3.2` gives 3.2.57, `bash:4.4` 4.4.23, `bash:5.2` 5.2.37). It is Alpine based, so it also has busybox ash as `/bin/sh`, and `apk add zsh bats` installs zsh 5.9 and Bats 1.12.0 into it. `zshusers/zsh` has tags per zsh version (`5.0.8` exists).

## Test setup

Decided 2026-10-01: bats on the host plus a Docker matrix over bash versions, with all running logic in a `justfile`.

- One bats suite; `TEST_SHELL` names the shell under test, and `tests/helpers/colorize.bash` runs `colorize` in a separate process of that shell.
- `just test` runs it on the host (default `bash zsh`, overridable).
- `tests/docker/Dockerfile` builds on `bash:<version>` and adds zsh, bats and just from Alpine. `just test-docker` runs `just test` inside each image for `bash:3.2`, `bash:4.4`, `bash:5.2` against bash, zsh and ash.
- Expected output is written in `cat -v` form.
- Every shell a test starts runs under `ulimit -t`, and `with_time_limit` ends a whole process group, as some inputs make colorize loop forever in a subshell that outlives its parent.
- Known bugs are pinned as they behave today. Each such test names a bug todo, which holds the test for the fixed behaviour.

Decided 2026-10-01: bats comes from the system's packages (Alpine's 1.12.0 in Docker, whatever the host has), not from a submodule.

## Open

- A zsh minimum below 5.9 (`zshusers/zsh` has older tags; whether bats installs there is unchecked). Set aside by the user on 2026-10-01.

## Relations

- Relates to: [Speed up the tag parser: no subshells, no `eval` per tag](01M3VFMXYB4FXZZGVQ1WYW1JT5-speed-up-the-tag-parser-no-subshells-no-eval-per-tag.md), since the parser rewrite must keep output byte for byte.
