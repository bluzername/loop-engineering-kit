#!/usr/bin/env bash
# install.sh - deploy the Loop-Engineering Kit into a Claude Code config directory
#
# Usage:
#   bash install.sh [--dry-run] [--copy] [--target DIR]
#
#   --dry-run     Print what would happen; change nothing.
#   --copy        Copy files instead of symlinking (detached from git).
#   --target DIR  Install into DIR instead of ~/.claude.
#
# Idempotent: re-running re-points symlinks or refreshes copies. Existing
# unrelated files in the target are never touched.
set -euo pipefail

DRY_RUN=0
COPY=0
TARGET="${HOME}/.claude"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --copy)    COPY=1 ;;
    --target)  TARGET="${2:?--target needs a directory}"; shift ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# Resolve the kit's own directory regardless of where it is invoked from.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say() { printf '%s\n' "$*"; }

# Run a command, or print it shell-quoted in dry-run mode. Arguments are passed
# through untouched, so paths containing spaces or quotes are safe.
run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '  [dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

# Install one kit subtree (commands, agents or skills) into the same-named
# subtree under TARGET, file by file, preserving relative structure.
install_tree() {
  local sub="$1"
  local src_dir="${SRC}/${sub}"
  local dst_dir="${TARGET}/${sub}"
  [[ -d "$src_dir" ]] || { say "  (skip ${sub}: not present)"; return; }

  say "==> ${sub} -> ${dst_dir}"
  run mkdir -p "$dst_dir"

  local f rel out
  while IFS= read -r -d '' f; do
    rel="${f#"${src_dir}/"}"
    out="${dst_dir}/${rel}"
    run mkdir -p "$(dirname "$out")"
    if [[ $COPY -eq 1 ]]; then
      run cp -f "$f" "$out"
    else
      # -n: do not descend into a symlinked dir; -f: replace an existing link or file
      run ln -sfn "$f" "$out"
    fi
    say "    ${rel}"
  done < <(find "$src_dir" -type f -print0)
}

say "Loop-Engineering Kit installer"
say "  source: ${SRC}"
say "  target: ${TARGET}"
say "  mode:   $([[ $COPY -eq 1 ]] && echo copy || echo symlink)$([[ $DRY_RUN -eq 1 ]] && echo ' (dry-run)')"
say ""

install_tree commands
install_tree agents
install_tree skills

say ""
say "Done. Start a fresh Claude Code session and type '/' to see:"
say "  /spec  /loop-run  /triage  /babysit  /loop-audit  /loop-audit-all"
say ""
say "Templates and docs are reference material; read them from the kit:"
say "  ${SRC}/templates/  ${SRC}/docs/"
