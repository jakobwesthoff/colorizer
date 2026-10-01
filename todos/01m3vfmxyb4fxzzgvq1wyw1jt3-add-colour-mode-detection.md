# Add an opt-in colour mode with terminal and NO_COLOR detection

**Priority:** 4 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

`colorize` always emits escape codes. Whether to colour is left to every
caller, which then has to call `colorize -s` or bypass it. Output piped to
a file or another program carries the codes.

The check is easy to get wrong. ekkocli's `k8s:drift` first checked for a
terminal inside a function its caller ran as `$(...)`, where stdout is the
substitution's pipe, so it never coloured. The fix was to decide in the
caller's own shell and pass the result down.

## Proposal (input, not decided)

- `COLORIZER_MODE=always|never|auto`, default `always`.
- `auto`: colour when the target is a terminal (`[ -t fd ]`), `NO_COLOR`
  is unset or empty, and `TERM` is not `dumb`.
- `never`: strip tags, as `-s` does.
- `colorize_detect [fd]` resolves `auto` once and stores the result
  (for example in `COLORIZER_ENABLED`). The caller runs it in its own shell,
  at startup or before printing.
- `colorize` and `colorize_code` use the stored result. They do not test
  the terminal per call, because callers run them inside `$(...)` (ekkocli
  sets `PS4="$(colorize -n ...)"`), where the test would always fail.
- stdout and stderr can differ (ekkocli's `_ekko_log_error` prints to
  stderr): to decide whether one stored result per fd is needed, or a
  `-u fd` option.

## Backwards compatibility

Default `always` keeps today's output. `auto` as default would remove
colours from piped output, which callers may rely on.

## Related

- `colorize_code` respects the mode: `01m3vfmxyb4fxzzgvq1wyw1jt2`.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is path A: `_ekko_drift_should_color` and
`_ekko_drift_stdout_is_terminal` go away; ekkocli calls `colorize_detect`
once, in the command's own shell.

## Decision

_Not yet established._
