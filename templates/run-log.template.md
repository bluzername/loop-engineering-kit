# Run log — <loop name>

> Per-run cost/outcome ledger for budget tracking. Append one row per loop run. Lets you see
> whether a loop is paying for itself before you graduate it to L3 / unattended.

| Date | Loop | Level | Rounds | Outcome | Approx tokens | Notes |
|------|------|-------|--------|---------|---------------|-------|
| 2026-06-26 | loop-run (SPEC.md) | L1 | 3 | all criteria pass | ~40k | dogfood run |
| | | | | | | |

## Budget policy

- **Ceiling per run:** <e.g. 8 rounds / 200k tokens>. The loop stops and reports at the ceiling.
- **Weekly budget:** <optional cap across all runs of this loop>.
- **Escalation:** if a loop repeatedly hits its ceiling without converging, demote it a level
  and revisit the spec — the criteria are probably wrong or the scope too big.
