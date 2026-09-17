# Loop-Engineering Kit for Claude Code

[![CI](https://github.com/bluzername/loop-engineering-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/bluzername/loop-engineering-kit/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

> Stop prompting your agent turn by turn. Design the **loop** that prompts it for you,
> point it at a goal, and walk away.

A reusable, project-agnostic kit: slash commands, a maker/checker agent pair, a skill,
templates and docs that install into your global `~/.claude` so loop engineering is
available in every repo you open with Claude Code.

## What is loop engineering?

Coined around Boris Cherny (head of Claude Code): *"I don't prompt Claude anymore. I have
loops running that prompt Claude and figuring out what to do. My job is to write loops."*

Three load-bearing ideas this kit operationalizes:

1. **Verification is the engine.** Giving the agent a way to check its own work is the single
   biggest quality lever. Every loop here has a *checker*.
2. **Specs replace prompts.** The hard job becomes stating what you want precisely enough that
   a machine can verify it: testable acceptance criteria, not a vague ticket.
3. **Durable memory.** Every caught mistake becomes a persistent correction (`CLAUDE.md`,
   a skill, or `STATE.md`) so the loop gets smarter across runs.

## Design principle: compose, do not reinvent

Claude Code already ships most of the loop engine. This kit adds the glue and wires existing
primitives into named loops:

| Primitive | Role in a loop |
|---|---|
| `/loop` skill | Recurring-interval runner inside a session |
| `/schedule` skill (scheduled tasks) | Cron-style trigger for the triage and maintenance loops |
| `/verify` skill | Run the app and observe behaviour; the checker for build loops |
| `/code-review`, `/security-review` skills | Automated review checkers |
| `gh pr checks --watch`, `gh run watch` | CI and PR monitoring for the babysitter loop (or a PR-activity subscription if your GitHub MCP offers one) |
| `Agent` tool and `~/.claude/agents/` | Maker/checker verification splits |

## What is in the box

```
loop-engineering-kit/
  install.sh            Idempotent installer (symlinks into ~/.claude). --dry-run, --copy, --target DIR
  commands/             Slash commands -> ~/.claude/commands/
    spec.md             /spec           Turn a vague request into a machine-checkable SPEC.md
    loop-run.md         /loop-run       Spec-driven build -> verify -> fix until criteria pass
    triage.md           /triage         Classify issues/PRs/deps; report (L1) or label (L2+)
    babysit.md          /babysit        Watch a PR and drive CI to green by loop level
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
    loop-patterns.md    The named loops, wired step by step
    governance.md       Budgets, stopping conditions, denylists, MCP scoping, anti-patterns
```

## Install

```bash
git clone https://github.com/bluzername/loop-engineering-kit.git
cd loop-engineering-kit
bash install.sh --dry-run          # preview, changes nothing
bash install.sh                    # symlink into ~/.claude
bash install.sh --copy             # detached copies instead of symlinks
bash install.sh --target /path     # install somewhere other than ~/.claude
```

The installer symlinks by default so `git pull` updates your installed commands; keep the
clone where it is. `--copy` gives you detached copies. Re-running is safe (idempotent) and
never touches unrelated files in the target.

After installing, start a fresh Claude Code session and type `/`. You should see `/spec`,
`/loop-run`, `/triage`, `/babysit`, `/loop-audit` and `/loop-audit-all`.

## The three loops

1. **Spec-driven build:** `/spec "<request>"` then `/loop-run`. The maker implements, the
   checker runs the acceptance commands, and the loop iterates until green or the budget
   ceiling is hit.
2. **PR babysitter / CI sweeper:** `/babysit <pr>`. Watches PR activity, diagnoses CI
   failures, and (by level) comments, fixes or re-kicks until green.
3. **Triage / maintenance:** `/triage` on a schedule. Report-only at L1, labels and draft PRs
   at L2.

See `docs/loop-patterns.md` for the full wiring.

## Phased rollout: L1 -> L2 -> L3

Start report-only and graduate as trust builds. Every command reads a `LOOP_LEVEL`
(default `L1`).

- **L1, report-only.** Loops observe and report. Zero writes. Tune your specs here.
- **L2, assisted.** Loops do the work but stop for approval before commit, push or merge.
- **L3, unattended.** Loops commit, push and open PRs on their own, gated by budget
  ceilings, stopping conditions and a denylist (no force-push, no secrets, no prod deploy).

Details in `docs/governance.md`.

## Development

CI runs shellcheck on the scripts, checks the frontmatter of every command, agent and skill,
exercises the installer (dry-run, symlink, idempotent re-run, copy) against a temporary
directory, smoke-tests `batch-audit.sh` on two fake projects, and rejects em or en dashes.
Dependabot keeps the GitHub Actions versions current.

## Sources

- [Loop engineering (BrainGrid)](https://braingrid.ai/blog/loop-engineering)
- [Loop engineering (Addy Osmani)](https://addyosmani.com/blog/loop-engineering)
- [The definitive guide to loop engineering (Developers Digest)](https://developersdigest.tech/blog/loop-engineering-definitive-guide)
- [cobusgreyling/loop-engineering](https://github.com/cobusgreyling/loop-engineering): loop-audit, loop-init, loop-cost and seven patterns
- [cocodedk/loop-engineering](https://github.com/cocodedk/loop-engineering): Boris Cherny methodology and the `agent-loop` skill
