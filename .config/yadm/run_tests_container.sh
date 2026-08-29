#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Find .local/bin from repo root or fallback to $HOME
if [[ -f "$REPO_ROOT/.local/bin/ssh-reconcile" ]]; then
  SRC_BIN="$REPO_ROOT/.local/bin"
elif [[ -f "$HOME/.local/bin/ssh-reconcile" ]]; then
  SRC_BIN="$HOME/.local/bin"
else
  echo "Error: Could not locate .local/bin scripts" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR/local/bin" "$WORK_DIR/config/yadm"
cp "$SRC_BIN/brewfile-reconcile" "$SRC_BIN/ssh-reconcile" "$WORK_DIR/local/bin/"
cp -R "$SCRIPT_DIR/tests" "$WORK_DIR/config/yadm/"
cp "$SCRIPT_DIR/Dockerfile" "$WORK_DIR/"

docker build -t yadm-tests "$WORK_DIR"
docker run --rm yadm-tests
