# SPEC: <short title>

> A spec a machine can check. Each acceptance criterion is a runnable pass/fail check, not prose.
> Produced by `/spec`, consumed by `/loop-run` and the `checker` sub-agent.

## Goal

<One sentence: the outcome you want.>

## Scope

- <What is in scope.>

### Out of scope

- <What this spec explicitly does NOT cover.>

## Acceptance criteria

Each criterion is a concrete, runnable check. Number them so the checker can report per-criterion.

- **C1** — <e.g. the build/typecheck exits 0: `make build` / `npm run build` / `cargo build`>
- **C2** — <e.g. `myapp --version` prints a semver string like `1.2.3`>
- **C3** — <e.g. `pytest tests/test_x.py::test_y` passes>
- **C4** — <e.g. file `X` contains string `Y` / no longer contains `Z`>

## Verification command block

A single copy-pasteable block that runs every criterion in order. `/loop-run`'s checker runs
this unattended. It should exit non-zero if any criterion fails.

```bash
set -e
# C1 — build/typecheck
make build
# C2 — CLI prints a semver version
myapp --version | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+'
# C3 — targeted test
# pytest tests/test_x.py::test_y
# C4 — file content assertion
# grep -q "Y" path/to/file
echo "ALL CRITERIA PASSED"
```

## Notes / decisions

- <Defaults chosen, constraints, links, anything the maker/checker should know.>
