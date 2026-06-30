---
description: Triage open issues / PRs — report-only at L1, apply labels and draft PRs at L2+
argument-hint: "[issues|prs|deps|changelog] [L1|L2|L3]"
---

# /triage — the maintenance loop

A discovery-and-classification pass meant to run on a **schedule** (via `CronCreate`) so the
backlog triages itself. Designed to be safe at L1 and useful unattended at L3.

Arguments: **$ARGUMENTS** — a target (`issues` default, or `prs`, `deps`, `changelog`) and an
optional loop level (default `L1`).

## Scope by target

- **issues** — list open issues, classify each: type (bug/feature/question/duplicate/stale),
  priority, and a one-line suggested next action. Use `mcp__github__list_issues` /
  `issue_read`. Flag anything that looks security-sensitive for human eyes — never auto-act on it.
- **prs** — list open PRs, classify: ready / needs-review / failing-CI / stale / mergeable.
  Use `list_pull_requests` / `pull_request_read`.
- **deps** — surface outdated/vulnerable dependencies using the project's native tooling
  (e.g. `swift package update --dry-run`, `npm outdated`, `pip list --outdated`). Report only;
  never bump versions at L1.
- **changelog** — draft release notes from commits since the last tag (`list_commits`,
  `list_tags`). Output a markdown block.

## By loop level

- **L1 (report-only):** Produce a single markdown **triage report** — a table plus a short
  "top 3 things a human should look at" list. Make zero writes. This is the default.
- **L2 (assisted):** May apply non-destructive metadata — labels, draft PRs for clear-cut dep
  bumps, a draft release. **Ask before** anything that closes, merges, or comments publicly.
- **L3 (unattended):** May apply labels and open draft PRs autonomously within the budget
  ceiling and denylist. Still never auto-close, auto-merge, or post on security issues.

## Running on a schedule

To make this a real loop, register it with cron (suggested cadences from the loop-engineering
patterns):

- issues → every 2h to daily
- deps → daily
- changelog → on tag / daily

Use `CronCreate` to schedule `/triage <target> <level>`. Keep `prs` out of cron — use
`/babysit` for live PR watching instead (it's event-driven, cheaper than polling).

## Output

A dated triage report. At L1 end with: *"Re-run at L2 to apply labels / open draft PRs, or
schedule with `CronCreate` for `/triage <target>`."* Log the run to `run-log.md` if the
project keeps one (budget tracking).
