---
description: Rank a directory of projects by loop-readiness and recommend the best one to test a loop on
argument-hint: "[directory, default: current directory]"
---

# /loop-audit-all - pick the best project to test a loop on

Run the kit's batch auditor over a directory of projects, then apply judgment to the finalists.
Cheap deterministic filter first, expensive LLM judge second - the same maker/checker economy
the kit preaches.

Target directory: **$ARGUMENTS** (default: the current directory).

## Steps

1. Run `bash <kit>/scripts/batch-audit.sh "$ARGUMENTS"` and show the ranked scorecard.
2. Take the top 2-3 by score and look closer at each (read-only): is the test suite real and
   green, or just a stub? Is there a small, well-scoped pending task you could write as a spec
   with machine-checkable acceptance criteria? Any macOS/hardware/secret blocker the heuristic
   missed?
3. Recommend ONE project as the first loop test, with reasons - lead with the verification path,
   since that's what makes a loop produce quality. Name the smallest concrete first task to try.
4. End with the exact next commands: `cd <project>` → `/loop-audit` (deep check) →
   `/spec "<small task>"` → `/loop-run SPEC.md L1`.

> Verify-path is load-bearing. Never recommend a project that scores 0 on verification, however
> nice it looks otherwise - a loop there just generates unverified diffs.
