# Fix restoring the colour of a dashed parent tag

**Priority:** 1 of 11 in the modernize series (cost/effectiveness order)

Closing a tag nested inside a tag whose name contains `-` (`light-*`,
`bg-*`, `bg-light-*`) emits an invalid escape sequence, so the parent's
colour is not restored.

```
colorize "<light-red>a<blue>b</blue>c</light-red>" | cat -v
^[[1;31ma^[[0;34mb^[[redmc^[[0m
```

`c` stays blue. Single-word parents (`<red>`) and closing the outermost
tag are not affected.

## Cause

Tag names are pushed onto the stack as written (`colorizer.sh:104`), which
the nesting check on line 106 relies on. The opening lookup converts `-` to
`_` first (line 115), because `-` is not valid in a variable name. The
closing branch reads the parent back from the stack and looks it up without
that conversion (line 124):

```bash
eval "ansiToken=\"\${COLORIZER_$(ARRAY_peek "stack")}\""
```

For `light-red` the shell evaluates `${COLORIZER_light-red}`, which is the
`${var-default}` expansion: the value of `COLORIZER_light`, or the word
`red` when that is unset. The result is `ESC[redm`, which terminals
discard. The default word is always the part after the first dash
(`bg-light-red` gives `light-red`).

## Proposal (input, not decided)

Convert the name read back from the stack the same way as on opening:

```bash
local parent
parent="$(ARRAY_peek "stack")"
eval "ansiToken=\"\${COLORIZER_${parent//-/_}}\""
```

Add a test (or README example) with a dashed parent and a nested tag.

## Backwards compatibility

Pure bug fix: only output that is broken today changes.

## Related

The parser rewrite (`01m3vfmxyb4fxzzgvq1wyw1jt5`) removes this code path,
but this one-line fix is worth having on its own and first.

## Decision

_Not yet established._
