#!/usr/bin/env bash
#
# install.sh — deploy the Loop-Engineering Kit into ~/.claude
#
# Usage:
#   bash loop-engineering-kit/install.sh [--dry-run] [--copy] [--target DIR]
#
#   --dry-run     Print what would happen; change nothing.
#   --copy        Copy files instead of symlinking (detached from git).
#   --target DIR  Install into DIR instead of ~/.claude.
#
# Idempotent: re-running re-points symlinks / refreshes copies. Existing
# unrelated files in ~/.claude are never touched.
set -euo pipefail

DRY_RUN=0
COPY=0
TARGET="${HOME}/.claude"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --copy)    COPY=1 ;;
    --target)  TARGET="${2:?--target needs a directory}"; shift ;;
    -h|--help) grep '^#' "$0" | sed 's/^#//'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
  shift
done

# Resolve the kit's own directory regardless of where it's invoked from.
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

say()  { printf '%s\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then say "  [dry-run] $*"; else eval "$*"; fi; }

# Install one source subtree into the matching target subtree, file by file.
# $1 = subdir under the kit (commands|agents|skills); $2 = subdir under TARGET
install_tree() {
  local sub="$1" dst_sub="$2"
  local src_dir="${SRC}/${sub}"
  local dst_dir="${TARGET}/${dst_sub}"
  [[ -d "$src_dir" ]] || { say "  (skip ${sub}: not present)"; return; }

  say "==> ${sub} -> ${dst_dir}"
  run "mkdir -p '${dst_dir}'"

  # Walk every file under src_dir, recreating relative structure in dst_dir.
  while IFS= read -r -d '' f; do
    local rel="${f#"${src_dir}/"}"
    local out="${dst_dir}/${rel}"
    run "mkdir -p '$(dirname "${out}")'"
    if [[ $COPY -eq 1 ]]; then
      run "cp -f '${f}' '${out}'"
    else
      # -n: don't descend into a symlinked dir; -f: replace existing link/file
      run "ln -sfn '${f}' '${out}'"
    fi
    say "    ${rel}"
  done < <(find "$src_dir" -type f -print0)
}

say "Loop-Engineering Kit installer"
say "  source: ${SRC}"
say "  target: ${TARGET}"
say "  mode:   $([[ $COPY -eq 1 ]] && echo copy || echo symlink)$([[ $DRY_RUN -eq 1 ]] && echo ' (dry-run)')"
say ""

install_tree "commands" "commands"
install_tree "agents"   "agents"
install_tree "skills"   "skills"

say ""
say "Done. Start a fresh Claude Code session and type '/' to see:"
say "  /spec  /loop-run  /triage  /babysit  /loop-audit"
say ""
say "Templates and docs are reference material — read them from the kit:"
say "  ${SRC}/templates/  ${SRC}/docs/"
