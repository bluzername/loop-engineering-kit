---
description: Spec-driven build loop — maker implements, checker verifies, iterate until acceptance criteria pass
argument-hint: "[path to SPEC.md] [L1|L2|L3]"
---

# /loop-run — the spec-driven build loop

Run a **maker → checker → fix** loop against a spec until every acceptance criterion passes
or the budget ceiling is hit. This is the loop-engineering core: you point it at a goal
(`SPEC.md`) and it prompts itself.

Arguments: **$ARGUMENTS** — optional path to the spec (default `SPEC.md`) and an optional
loop level (`L1`/`L2`/`L3`, default `L1`). Read the loop level from the argument, else from a
`LOOP_LEVEL` env var, else default `L1`. See `docs/governance.md` for what each level permits.

## Preconditions

1. Load the spec. If it's missing, tell the user to run `/spec "<request>"` first and stop.
2. Confirm the spec has a runnable **Verification command block**. If not, stop and ask the
   user to make the criteria machine-checkable — a loop with no checker is not a loop.

## The loop

Repeat until all criteria pass OR you hit a stop condition:

1. **Maker.** Launch the `maker` sub-agent (Agent tool, `subagent_type: "maker"`) with: the
   spec, the current failing criteria, and the checker's last report. It implements the
   smallest change that moves a failing criterion toward passing. It does NOT mark anything
   done — only the checker does that.
2. **Checker.** Launch the `checker` sub-agent (`subagent_type: "checker"`) with the spec's
   verification command block. It runs every criterion, reports per-criterion PASS/FAIL with
   evidence (command output), and adversarially tries to break "passing" criteria. Reuse the
   `/verify` skill for behavior-level checks and `/code-review` for the diff when criteria are green.
3. **Decide.**
   - All criteria PASS → go to **Finish**.
   - Some FAIL → record the failures, feed them back to step 1.
4. **Memory.** Any mistake the checker catches that the maker should have known → append a
   one-line correction to the project `CLAUDE.md` (e.g. "Always run the release build, not the
   debug build, before claiming a build passes"). This is how the loop gets smarter.

### Stop conditions (whichever comes first)

- All acceptance criteria pass.
- **Budget ceiling:** default max 8 maker/checker rounds. Stop and report.
- **No progress:** 2 consecutive rounds with the same set of failing criteria → stop, report
  the wall you hit, and ask the user for direction. Do not thrash.

## By loop level

- **L1 (report-only):** Run the full loop in a scratch/worktree but **do not commit or push**.
  Report the final diff, which criteria pass, and what's left. This is the default — use it to
  validate that the spec is right before trusting the loop.
- **L2 (assisted):** Apply changes to the working tree. When all criteria pass, **stop and ask**
  before committing/pushing.
- **L3 (unattended):** When all criteria pass, commit with a spec-referencing message, push to
  the feature branch, and open a draft PR. Obey the denylist in `docs/governance.md`
  (no force-push, no secrets, no prod deploy).

## Finish

Print: criteria results table (C1…Cn, PASS/FAIL, evidence), the round count, any CLAUDE.md
corrections recorded, and the next action appropriate to the loop level.
