#!/usr/bin/env bash
#
# batch-audit.sh - rank a directory of projects by loop-readiness.
#
# Read-only. Scans each immediate subdirectory and scores 0-10 across the same
# dimensions as the /loop-audit command, so you can pick the best project to test
# a loop on. Highest score = best first candidate. Run the full /loop-audit on the
# top 2-3 for the judgment call.
#
# Usage:
#   bash batch-audit.sh [DIR]      # DIR defaults to the current directory
#
# Scoring (max 10):
#   verify 0-4  tests(+2) build-manifest(+1) lint(+1)   <- weighted heaviest
#   ci     0-2  CI workflows present
#   mem    0-1  CLAUDE.md present
#   port   0-2  Linux/CI-friendly(+1, unless macOS-only red flags) + git repo(+1)
#   spec   0-1  SPEC.md or issue template present
set -euo pipefail

ROOT="${1:-.}"

if [[ ! -d "$ROOT" ]]; then
  echo "Not a directory: $ROOT" >&2
  echo "Usage: bash batch-audit.sh [DIR]   (default: current directory)" >&2
  exit 1
fi

# Heavy/generated dirs we never want to descend into.
PRUNE=( -name .git -o -name node_modules -o -name vendor -o -name target \
        -o -name .build -o -name build -o -name dist -o -name .venv -o -name venv )

# find within a project, pruning heavy dirs, bounded depth. Args: <dir> <find-tests...>
pfind() {
  local d="$1"; shift
  find "$d" -maxdepth 4 \( "${PRUNE[@]}" \) -prune -o "$@" -print 2>/dev/null
}

# Does a root-level file matching any of the given globs exist? Args: <dir> <glob...>
root_glob() {
  local d="$1"; shift
  local g
  for g in "$@"; do
    compgen -G "$d/$g" >/dev/null 2>&1 && return 0
  done
  return 1
}

has_tests() {
  local d="$1"
  if [[ -n "$(pfind "$d" -type d \( -iname test -o -iname tests -o -iname spec \
        -o -name __tests__ -o -name Tests \) )" ]]; then return 0; fi
  if [[ -n "$(pfind "$d" -type f \( -name '*_test.*' -o -name '*.test.*' \
        -o -name '*.spec.*' -o -name 'test_*.py' \) )" ]]; then return 0; fi
  if [[ -f "$d/package.json" ]] && grep -Eq '"test"[[:space:]]*:' "$d/package.json" 2>/dev/null \
       && ! grep -Eq '"test"[[:space:]]*:[[:space:]]*"[^"]*no test specified' "$d/package.json" 2>/dev/null; then
    return 0
  fi
  return 1
}

has_build_manifest() {
  root_glob "$1" package.json pyproject.toml setup.py Cargo.toml go.mod \
    Package.swift pom.xml build.gradle build.gradle.kts Makefile CMakeLists.txt
}

has_lint() {
  root_glob "$1" '.eslintrc*' .swiftlint.yml ruff.toml .ruff.toml '.golangci.y*ml' \
    .flake8 .rubocop.yml biome.json .pre-commit-config.yaml
}

has_ci() {
  local d="$1"
  [[ -d "$d/.github/workflows" ]] && return 0
  root_glob "$d" .gitlab-ci.yml azure-pipelines.yml && return 0
  [[ -d "$d/.circleci" ]] && return 0
  return 1
}

# macOS-only red flags => loop can't run on plain Linux/CI.
is_macos_locked() {
  local d="$1"
  [[ -n "$(pfind "$d" -type d -name '*.xcodeproj')" ]] && return 0
  [[ -n "$(pfind "$d" -type f -name '*.entitlements')" ]] && return 0
  if [[ -f "$d/Package.swift" ]] && grep -q '\.macOS' "$d/Package.swift" 2>/dev/null; then return 0; fi
  if [[ -n "$(pfind "$d" -type f \( -name '*.sh' -o -name '*.swift' \))" ]] \
     && grep -rqIl -e codesign -e CoreBluetooth -e AVFoundation \
        --include='*.sh' --include='*.swift' "$d" 2>/dev/null; then return 0; fi
  return 1
}

has_spec() {
  local d="$1"
  [[ -f "$d/SPEC.md" ]] && return 0
  [[ -d "$d/.github/ISSUE_TEMPLATE" ]] && return 0
  return 1
}

# ---- scan ----
rows=()
for d in "$ROOT"/*/; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"

  v=0; notes=()
  has_tests "$d"          && v=$((v+2)) || notes+=("no tests")
  has_build_manifest "$d" && v=$((v+1)) || notes+=("no build manifest")
  has_lint "$d"           && v=$((v+1))

  ci=0;  has_ci "$d"   && ci=2 || notes+=("no CI")
  mem=0; [[ -f "$d/CLAUDE.md" ]] && mem=1

  port=0
  if is_macos_locked "$d"; then notes+=("macOS-only"); else port=$((port+1)); fi
  [[ -d "$d/.git" ]] && port=$((port+1)) || notes+=("not a git repo")

  spec=0; has_spec "$d" && spec=1

  score=$((v+ci+mem+port+spec))
  note="$(IFS=', '; echo "${notes[*]:-ok}")"
  rows+=("$(printf '%d\t%s\t%d/4\t%d/2\t%d/1\t%d/2\t%d/1\t%s' \
            "$score" "$name" "$v" "$ci" "$mem" "$port" "$spec" "$note")")
done

if [[ ${#rows[@]} -eq 0 ]]; then
  echo "No subdirectories found under: $ROOT"
  exit 0
fi

echo "Loop-readiness audit of: $ROOT"
echo
printf '%-28s %5s  %-5s %-4s %-4s %-5s %-5s  %s\n' \
  PROJECT SCORE VERIFY CI MEM PORT SPEC NOTES
printf '%-28s %5s  %-5s %-4s %-4s %-5s %-5s  %s\n' \
  "----------------------------" "-----" "-----" "----" "----" "-----" "-----" "-----"

best_line=""
while IFS=$'\t' read -r score name verify ci mem port spec note; do
  [[ -z "$best_line" ]] && best_line="$name ($score/10)"
  printf '%-28s %5s  %-5s %-4s %-4s %-5s %-5s  %s\n' \
    "$name" "$score/10" "$verify" "$ci" "$mem" "$port" "$spec" "$note"
done < <(printf '%s\n' "${rows[@]}" | sort -t$'\t' -k1,1nr -k2,2)

echo
echo "Recommendation: $best_line is the strongest first candidate."
echo "Next: cd into it and run /loop-audit for the deep check, then /spec a small task and /loop-run it at L1."
echo
echo "Reminder: verify-path is the load-bearing column. A high score with verify 0/4 still isn't loop-ready."
