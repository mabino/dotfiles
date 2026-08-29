#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

mkdir -p "$WORK_DIR/local/bin" "$WORK_DIR/config/yadm"
cp "$HOME/.local/bin/brewfile-reconcile" "$HOME/.local/bin/ssh-reconcile" "$WORK_DIR/local/bin/"
cp -R "$SCRIPT_DIR/tests" "$WORK_DIR/config/yadm/"
cp "$SCRIPT_DIR/Dockerfile" "$WORK_DIR/"

docker build -t yadm-tests "$WORK_DIR"
docker run --rm yadm-tests
