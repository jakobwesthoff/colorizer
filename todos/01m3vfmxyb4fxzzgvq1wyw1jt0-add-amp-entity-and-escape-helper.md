# Decode `&amp;` and add `colorize_escape` for untrusted text

**Priority:** 6 of 10 in the modernize series (cost/effectiveness for
k8s:drift, re-evaluated 2026-10-01)

Text from outside the script (command output, cluster values, user input)
cannot be passed through `colorize` safely today:

- Only `&lt;` and `&gt;` are decoded (`colorizer.sh:174` and 175). There
  is no `&amp;`, so a literal `&lt;` cannot be written at all.
- There is no helper to escape a value; callers must know to replace
  `<` and `>` themselves.
- Unescaped text that looks like a tag is taken as markup and replaces the
  output with an error: `colorize "value <b> here"` prints
  `Could not find closing tag for <b>`, `colorize "value </div> here"`
  prints `Mismatching colorize tag nesting at <>...</div>`. (Text between
  `<` and `>` that is not a valid tag name is printed as it is.)

ekkocli's `k8s:drift` prints cluster values and could not use `colorize`
for its lines for these reasons.

## Proposal (input, not decided)

1. Decode `&amp;` after `&lt;` and `&gt;`, so `&amp;lt;` becomes `&lt;`.
2. A function that entity-encodes a value, using only parameter expansion
   (no subshell), `&` first:

   ```bash
   # Encodes a value so `colorize` prints it as it is: `&` first, so the
   # entities added for `<` and `>` are not encoded twice.
   colorize_escape() {
       local text="${1}"
       text="${text//&/&amp;}"
       text="${text//</&lt;}"
       text="${text//>/&gt;}"
       printf '%s' "${text}"
   }
   ```

   Callers inside `$(...)` pay one subshell; a `-v name` variant that
   assigns instead of printing avoids it in bash (`printf -v`).
3. README: interpolate external text only through `colorize_escape`, and
   after `--`.

An escaped value never contains `<`, so it never reaches the tag parser or
`eval`. This closes the injection for callers who escape, without touching
the parser.

## Backwards compatibility

`colorize_escape` is new. Decoding `&amp;` changes the output of text that
contains a literal `&amp;` today (printed as `&amp;`, then as `&`). Assumed
rare; to be named in the changelog. Shells other than bash and zsh need
checking for `${var//pattern/replacement}`; the README claims busybox ash
works, and the existing code on lines 174 and 175 already uses that
expansion.

## Related

- Backslashes in values: `01m3vfmxyb4fxzzgvq1wyw1jt1`.
- Making unescaped callers safe as well: `01m3vfmxyb4fxzzgvq1wyw1jt5`.

## For k8s:drift

Two ways k8s:drift can use colorizer (re-evaluated 2026-10-01):

- **Path A**: drift keeps rendering in jq and takes the escape codes from
  colorizer instead of writing them itself. Todos 1 to 4 of this series.
- **Path B**: drift's jq program emits colorizer markup and colorize
  prints it. Todos 6 to 10 of this series, all of them needed together.

Path A removes drift's own colour code without touching its renderer. Path
B would also take the escape codes out of the renderer. Which path drift
takes is not decided.

This todo is path B: drift's cluster values would pass through colorize
and need escaping (in jq: `gsub`). On path A no value reaches colorize.

## Decision

_Not yet established._
