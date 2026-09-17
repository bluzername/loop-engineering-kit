---
description: Turn a vague request into a machine-checkable SPEC.md with testable acceptance criteria
argument-hint: "<what you want, in plain words>"
---

# /spec - write a spec a machine can check

Loop engineering takes prompting off your plate and hands you a harder job: **deciding what
you actually want and stating it precisely enough that a machine can check the result.** This
command does that step. The spec - not a prompt - is what `/loop-run` and the checker agent
verify against.

## Your task

Turn the request below into a spec at `SPEC.md` in the current project, using the kit's
`templates/SPEC.template.md` as the structure.

Request: **$ARGUMENTS**

### Steps

1. **Understand the codebase first.** Identify the language, build command, test command, and
   how a human would currently confirm this request is done. Reuse existing patterns - do not
   invent new conventions. If there is no way to verify (no tests, no runnable check), say so
   explicitly and propose the smallest verification you could add.
2. **Clarify only true ambiguity.** If the request is genuinely underspecified in a way that
   changes the acceptance criteria, ask the user 1-3 sharp questions with `AskUserQuestion`.
   Otherwise pick sensible defaults and note them.
3. **Write `SPEC.md`** with these sections (from the template):
   - **Goal** - one sentence, the outcome.
   - **Scope / Out of scope** - what's in, what's explicitly not.
   - **Acceptance criteria** - the heart of the spec. Each criterion MUST be a concrete,
     **runnable pass/fail check**, not prose. Prefer exact commands and expected results:
     - the build/typecheck exits 0 (`make build` / `npm run build` / `cargo build` / `tsc`)
     - `<binary> --version` prints a semver string
     - `pytest tests/test_foo.py::test_bar` passes
     - a specific file contains / no longer contains a given string
     Number them C1, C2, … so the checker can report per-criterion.
   - **Verification command block** - a single copy-pasteable block that runs every criterion
     in order, so `/loop-run`'s checker can execute it unattended.
   - **Notes / decisions** - defaults you chose, links, constraints.
4. **Do not implement anything.** `/spec` only produces the spec. Hand off to `/loop-run`.

### Output

After writing `SPEC.md`, print a short summary: the goal, the numbered acceptance criteria,
and the exact verification command block. End with: *"Run `/loop-run` to build against this spec."*

> If a criterion can't be expressed as a runnable check, it isn't an acceptance criterion yet  - 
> rewrite it until it is, or move it to Notes.
