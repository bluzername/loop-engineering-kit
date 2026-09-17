---
name: agent-loop
description: Run a goal-directed agent loop or a chain of loops with hybrid verification (objective checks, LLM-judge, human sign-off). Use when the user wants to point an agent at a goal and have it iterate to completion rather than prompting step by step.
---

# agent-loop

A runnable harness for the core loop-engineering pattern: **sense → decide → act → check**,
repeated until a goal's acceptance criteria are met or a budget ceiling stops it. Supports a
single loop or a **chain** where each loop's output feeds the next.

This skill is the conceptual engine behind `/loop-run`. Use `/loop-run` for the common
spec-driven build case; use this skill directly when you need a custom loop or a multi-stage
chain.

## Anatomy of a loop (define these before running)

- **Goal** - the outcome, ideally a `SPEC.md` with machine-checkable criteria.
- **Trigger** - what starts it (manual, a cron schedule, a PR/CI event).
- **Scope** - files/areas the loop may touch.
- **Action** - the generator step (the `maker` sub-agent, or `/spec` then implement).
- **Check** - the verifier step. Always present. See hybrid verification below.
- **Budget ceiling** - max rounds and/or token target. Hard stop.
- **Stopping conditions** - all criteria pass; budget hit; no progress for N rounds.
- **Reporting** - what the loop emits at the end and per round.

## Hybrid verification (pick the cheapest sufficient check)

1. **Objective** (preferred) - tests, build, lint, a runnable command with a pass/fail exit
   code. Use the `checker` sub-agent and the `/verify` skill. Trust this over everything.
2. **LLM-judge** - for criteria without a clean exit code (clarity of docs, API ergonomics),
   spawn an independent agent to judge against an explicit rubric. Use a separate agent from
   the one that did the work, and default to skepticism.
3. **Human sign-off** - for irreversible or high-stakes steps (publishing, prod, schema
   migrations), stop and require explicit approval regardless of loop level.

A loop with no check is not a loop - refuse to run one until a check is defined.

## Single loop (procedure)

```
load goal/spec
round = 0
while not all_criteria_pass and round < ceiling:
    round += 1
    act     -> maker sub-agent makes the smallest progressing change
    check   -> checker sub-agent runs verification, reports per-criterion
    if no_progress_for(2 rounds): stop("hit a wall"), ask human
    record any MEMORY: corrections -> CLAUDE.md
finish -> report criteria table, rounds, next action by loop level
```

## Loop chains

For work too big for one loop, decompose into stages, each its own loop with its own check;
the output (and verified state) of stage N is the input to stage N+1. Put a verification gate
between stages so a bad stage can't silently poison the next. Example chain: `/spec` →
`design loop (LLM-judge on the approach)` → `build loop (objective tests)` →
`review loop (/code-review + /security-review)` → human sign-off.

## Loop level & safety

Read the loop level (L1/L2/L3) and obey `docs/governance.md`: L1 reports only, L2 acts behind
approval, L3 runs unattended within budget and the denylist. Log each run to `run-log.md` for
budget tracking. Never disable a check to make a loop "pass."
