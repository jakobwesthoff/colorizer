# Todos

This directory is an [ntropy](https://ntropy.westhoffswelt.de) vault
holding the deferred work of colorizer: bugs, features, refactors and
open questions. Each todo is one Markdown note in `all-notes/`, named
`<ULID>-<slug>.md`. The ULID is the todo's permanent identity.
`by-component/` and `by-tag/` are views, derived symlink trees that git
ignores.

Run every command with the vault pinned and `-n`, from anywhere in the
repository. There is no `.ntropy-vault` pointer file on purpose, so
ntropy commands for other vaults keep working inside this repository.

## Format

```yaml
---
title: "Settings watcher drops a write during reload"
kind: bug
component: settings
status: blocked     # requires a Depends on or Blocked by line
impact: high
horizon: next
origin: review
tags: [concurrency]
---
```

- `title` (required): always double-quoted. It names the concrete subject
  and the change or problem, in sentence case; no prefix such as a kind,
  component or ticket label goes before it. The H1 repeats it.
- `kind` (required): `bug` (wrong today, even if unconfirmed),
  `feature` (new capability), `improvement` (better for users or
  operators, not wrong now), `refactor` (restructures code, no
  behaviour change), `docs`, `chore` (no behaviour or logic change:
  dependencies, build, CI, comments, manual release checks),
  `investigation` (a question to settle by research or by the user's
  decision), `plan` (coordinates todos that point at it). When several
  fit, take the first of bug, feature, improvement, refactor, docs,
  chore; `plan` and `investigation` win over those, and a plan wins over
  an investigation.
- `component` (required): one value from the list below.
- `status`: `needs-discussion` (the direction is unsettled; discuss
  before anyone works on it) or `blocked` (waits on another todo or an
  outside event). Absent means ready. `needs-discussion` wins when both
  apply.
- `impact`: `critical` (loses data, breaks core use, or an exploitable
  security hole), `high` (degrades a core feature, fails often, or
  hardens a security boundary), or `low` (polish). Absent means normal.
- `horizon`: `next` or `someday`. Absent means normal backlog. A
  `someday` todo ends with a `## Revisit when` section naming what
  brings it back, or "No trigger known; reconsider at the next sweep."
- `origin`: the first that fits of `incident`, `review`, `upstream`,
  `implementation`, `discussion`, `request`, `idea`; absent means not
  recorded.
- `tags`: topics from the list below.

Values are written exactly as listed. Defaults are never written: no
`status: ready`, no `impact: normal`, no `horizon: backlog`. Never add
`id`, `created`, `modified` or another date field; the ULID carries the
creation time.

The body opens with a paragraph that stands alone. Relations to other
todos go in a final `## Relations` section, one line per target:
*Depends on*, *Part of* and *Relates to* link `[Title](<ULID>-<slug>.md)`,
where the filename is
`basename "$(ntropy --vault "$VAULT" search -n -p <ULID>)"` and the
target must already exist; a todo in another repository is written as
plain text, `<repository> todo <ULID> (<title>)`. *Blocked by* names an
outside event in plain text. A relation is written on the dependent
side only: the todo that depends on, is blocked by, or is part of
another carries the line; *Relates to* goes on the todo with the larger
ULID; a plan never lists its steps. A todo with a *Depends on* line to
an existing todo, or a *Blocked by* that still holds, has
`status: blocked`. Code comments and docs refer to a todo by its
filename without a path, `<ULID>-<slug>.md`; when a retitle renames it,
those citations change with it (`rg -i <ulid>` finds them).

## Components

- `library`: the `colorize` function, argument parsing, tag parser and palette (`Library/colorizer.sh`), and the array layer for bash and zsh (`Library/Compatibility/`)
- `project`: build, CI, release, repository-wide docs and product
  decisions; only when no other component fits

## Tags

- `performance`: speed of the parser and the output
- `testing`: the Bats suite and its Docker matrix
- `compatibility`: support for bash, zsh and busybox ash versions

## Related repositories

- `../watson-dashboard`

## Filing and editing a todo

Never create a note file in `all-notes/` by hand: the ULID must come
from ntropy. Compose the whole note first, including the filenames of
the todos it links, then let ntropy allocate it and write it in the same
Bash invocation, since `new` leaves an empty note until `write` runs.
The title goes to `new` in single quotes (an apostrophe inside becomes
`'\''`, as in `'Don'\''t drop writes'`) and into the frontmatter in
double quotes:

```bash
VAULT="$(git rev-parse --show-toplevel)/todos"
note=$(ntropy --vault "$VAULT" new -n --empty -p 'Settings watcher drops a write during reload')
ntropy --vault "$VAULT" write -n "$note" <<'EOF'
---
title: "Settings watcher drops a write during reload"
kind: bug
component: settings
---
# Settings watcher drops a write during reload

What is wrong, where, and why it matters.
EOF
```

If `write` fails, fix the text and run `write` again on the same note.
To edit a todo, edit the file `ntropy --vault "$VAULT" search -n -p <ULID>`
prints, then run `ntropy --vault "$VAULT" reconcile -n`. Before
committing, `ntropy --vault "$VAULT" reconcile -n --strict` must exit 0.

## Finding work

```bash
VAULT="$(git rev-parse --show-toplevel)/todos"
ntropy --vault "$VAULT" search -n 'not status:blocked and not status:needs-discussion and not horizon:someday and not kind:plan'
ntropy --vault "$VAULT" search -n status:needs-discussion
ntropy --vault "$VAULT" search -n 'impact:critical or impact:high'
ntropy --vault "$VAULT" search -n component:library
ntropy --vault "$VAULT" search -n -P '<ULID>'     # print one todo
```

## Closing a todo

A finished todo is deleted in the commit that finishes the work, or,
when the work is already committed, in a commit of its own that names
those commits by short SHA. Before deleting it:

1. Find every reference: `ntropy --vault "$VAULT" search -n "text:<ulid>"`
   for other todos, and `rg -il --hidden --glob '!.git' <ulid>` in the
   repository and the related repositories above.
2. Remove its *Depends on* line from every todo that depends on it, and
   their `status: blocked` when no blocker line remains. If the todo is
   dropped rather than done, re-evaluate each dependent as well: drop
   it, rewrite it, or set `status: needs-discussion` with a Decisions
   line naming the dropped prerequisite. Update or remove other links
   and the docs that mention it.
3. If it has a *Part of* line, update its plan's Steps prose; when no
   other todo has a *Part of* line to that plan, close the plan too.
4. An investigation's findings go into an ADR, the docs or the todos it
   produced; if none fits, ask whether to keep them at all.
5. Delete it with `ntropy --vault "$VAULT" delete -n -f <ULID>`.

Git history is the archive. Work that landed only partly gets the todo
rewritten to cover what remains instead.
