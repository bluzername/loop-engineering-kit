# Loop-Engineering Kit for Claude Code

> Stop prompting your agent turn-by-turn. Design the **loop** that prompts it for you,
> point it at a goal, and walk away.

This is a **reusable, project-agnostic** kit. It installs a small set of slash commands,
sub-agents, a skill, templates, and docs into your **global** `~/.claude` so loop
engineering is available in *every* repo you open with Claude Code.

## What is loop engineering?

Coined around Boris Cherny (head of Claude Code): *"I don't prompt Claude anymore. I have
loops running that prompt Claude and figuring out what to do. My job is to write loops."*

Three load-bearing ideas this kit operationalizes:

1. **Verification is the engine.** Giving the agent a way to check its own work is the single
   biggest quality lever (~2–3x). Every loop here has a *checker*.
2. **Specs replace prompts.** The hard job becomes stating what you want precisely enough that
   a *machine* can verify it — testable acceptance criteria, not a vague ticket.
3. **Durable memory.** Every caught mistake becomes a persistent correction (`CLAUDE.md`,
   a skill, or `STATE.md`) so the loop gets smarter across runs.

## Design principle: compose, don't reinvent

Claude Code already ships most of the loop *engine*. This kit adds the missing **glue** and
wires existing primitives into named loops. It reuses:

| Primitive | Role in a loop |
|---|---|
| `/loop` skill | The recurring-interval runner — the core loop engine |
| `/verify` skill | Run the app and observe behavior — the checker for build loops |
| `/code-review`, `/security-review` skills | Automated review checkers |
| `subscribe_pr_activity` (github MCP) | The PR babysitter / CI sweeper engine |
| `CronCreate` / `ScheduleWakeup` | Scheduling for triage & maintenance loops |
| Sub-agents (`Agent` tool / `~/.claude/agents/`) | Maker/checker verification splits |

## What's in the box

```
loop-engineering-kit/
  install.sh            Idempotent installer (symlinks into ~/.claude). Supports --dry-run.
  commands/             Slash commands -> ~/.claude/commands/
    spec.md             /spec       Turn a vague request into a machine-checkable SPEC.md
    loop-run.md         /loop-run   Spec-driven build->verify->fix until criteria pass
    triage.md           /triage     Classify issues/PRs; report (L1) or label (L2)
    babysit.md          /babysit    Watch a PR via subscribe_pr_activity + handling policy
    loop-audit.md       /loop-audit     Score whether THIS repo is loop-ready
    loop-audit-all.md   /loop-audit-all Rank a directory of projects; recommend the best to test
  agents/               Sub-agents -> ~/.claude/agents/
    maker.md            Generator: implements against the spec
    checker.md          Adversarial verifier: runs the acceptance commands, tries to refute
  skills/
    agent-loop/SKILL.md Runnable single-loop / loop-chain skill with hybrid verification
  scripts/
    batch-audit.sh      Read-only loop-readiness scanner used by /loop-audit-all
  templates/
    SPEC.template.md    Goal, scope, machine-checkable acceptance criteria
    STATE.template.md   Durable loop spine: goal, progress, decisions, blockers
    run-log.template.md Per-run cost/outcome log for budget tracking
  docs/
    loop-patterns.md    The named loops, wired step-by-step
    governance.md       Budgets, stopping conditions, denylists, MCP scoping, anti-patterns
```

## Install

```bash
git clone https://github.com/bluzername/loop-engineering-kit.git
cd loop-engineering-kit
bash install.sh --dry-run   # preview
bash install.sh             # symlink into ~/.claude
```

The installer **symlinks** by default so `git pull` updates your installed commands. Use
`--copy` if you prefer detached copies. Re-running is safe (idempotent). Keep the cloned repo
where it is (symlinks point back into it).

After installing, start a fresh Claude Code session and type `/` — you should see
`/spec`, `/loop-run`, `/triage`, `/babysit`, `/loop-audit`, `/loop-audit-all`.

## The three loops

1. **Spec-driven build** — `/spec "<request>"` → `/loop-run`. Maker implements, checker runs
   the acceptance commands, the loop iterates until green or the budget ceiling is hit.
2. **PR babysitter / CI sweeper** — `/babysit <pr>`. Subscribes to PR activity, diagnoses CI
   failures, and (by level) comments / fixes / re-kicks until green.
3. **Triage / maintenance** — `/triage` on a `CronCreate` schedule. Report-only at L1, labels
   and draft PRs at L2.

See `docs/loop-patterns.md` for the full wiring.

## Phased rollout: L1 → L2 → L3

Start **report-only**, graduate as trust builds. Every command reads a `LOOP_LEVEL`
(default `L1`).

- **L1 — report-only.** Loops observe and report. Zero writes. Tune your specs here.
- **L2 — assisted.** Loops do the work but stop for approval before commit/push/merge.
- **L3 — unattended.** Loops commit, push, and open PRs on their own — gated by budget
  ceilings, stopping conditions, and a denylist (no force-push, no secrets, no prod deploy).

Details in `docs/governance.md`.

## Sources

- braingrid.ai/blog/loop-engineering
- addyosmani.com/blog/loop-engineering
- developersdigest.tech/blog/loop-engineering-definitive-guide
- github.com/cobusgreyling/loop-engineering — loop-audit / loop-init / loop-cost, 7 patterns
- github.com/cocodedk/loop-engineering — Boris Cherny methodology, `agent-loop` skill
