# Add an opt-in nesting mode that combines styles

**Priority:** 9 of 11 in the modernize series (cost/effectiveness order)

Nested tags replace each other instead of combining. Every built-in palette
value starts with `0;` (a full reset), and closing a tag re-emits only the
parent's code (`colorizer.sh:142` to 150). Observed:

```
COLORIZER_bold=1
colorize "<bold>a<red>b</red>c</bold>"
^[[1ma^[[0;31mb^[[1mc^[[0m
```

`b` is red but not bold. `c` is bold and still red, because re-emitting
`1` does not undo the red.

```
colorize "<bg-red>a<red>b</red></bg-red>"
^[[0;37;41ma^[[0;31mb^[[0;37;41m^[[0m
```

The background is lost under the inner colour.

An attribute inside a colour already works, because attribute codes have
no `0;`: `<red><bold>x</bold></red>`.

## Proposal (input, not decided)

`COLORIZER_NESTING=compose` (default: today's behaviour):

- On opening a tag, emit `0;` followed by the codes of every tag on the
  stack, outermost first, each with a leading `0;` removed.
- On closing, emit the same for what remains on the stack, or the reset
  when it is empty.
- The palette values stay as they are; stripping the `0;` while emitting
  keeps callers' overrides working.

Later codes win where they conflict (an inner foreground colour replaces
the outer one), so same-kind nesting looks as today.

## Backwards compatibility

Opt-in, because the output changes visibly in some cases: an outer
`light-*` (`1;3x`) with an inner colour keeps the bold, where today the
inner colour clears it. Making it the default would be a major version.

## Related

- The parser rewrite keeps the stack as a string, which makes joining the
  codes cheap: `01m3vfmxyb4fxzzgvq1wyw1jt5`.
- ekkocli's `k8s:drift` only needs nesting if it moves to markup via the
  filter mode (`01m3vfmxyb4fxzzgvq1wyw1jt6`), so this pairs with that.

## Decision

_Not yet established._
