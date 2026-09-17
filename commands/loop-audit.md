---
description: Score whether the current repo is loop-ready - does the agent have a way to verify its own work?
argument-hint: "(no args)"
---

# /loop-audit - is this repo loop-ready?

Loops only work when the agent can **verify its own work**. This command scores the current
repository's readiness and tells you what to fix before trusting any unattended loop. Inspired
by `loop-audit` from github.com/cobusgreyling/loop-engineering.

## What to check (read-only - make no changes)

Score each dimension 0-2 (0 = absent, 1 = partial, 2 = solid) and explain the evidence:

1. **Verification path (most important).** Is there a command that proves the code works?
   - A test command (`swift test`, `pytest`, `npm test`, …) that actually runs?
   - A build/typecheck that fails on breakage (`swift build -c release`, `tsc`, …)?
   - A lint/format gate (SwiftLint, ruff, eslint, …)?
   - A runnable smoke check via the `/verify` skill?
2. **CI.** Is there `.github/workflows/` that runs the above on PRs? Which jobs, which runner?
3. **Spec discipline.** Is there a `SPEC.md` / acceptance-criteria habit, or an issue template
   with testable criteria?
4. **Durable memory.** Is there a `CLAUDE.md` capturing conventions and past corrections?
   A `STATE.md` / `run-log.md` spine for long-running loops?
5. **Safety rails.** Are there scoped permissions / a denylist / branch protection so an
   unattended loop can't do damage?

## Output

1. A scorecard table (dimension, score 0-2, evidence).
2. An overall **loop-readiness level**:
   - **0-4:** L1 only. Loops can report, not act - there's no reliable checker.
   - **5-7:** L2 ready. Loops can do work behind human approval.
   - **8-10:** L3 candidate. Strong enough verification to consider unattended loops.
3. The **single highest-leverage fix** to raise the score (usually: add a real verification
   command, then wire it into CI).
4. If verification is missing, name the smallest concrete thing to add for THIS project's
   stack - and offer to draft it (don't write it unless asked).

> A loop pointed at a repo that scores 0 on verification is just an expensive way to generate
> unverified diffs. Fix the checker first.
