#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export FLOWKEY_CONFIGURATION=release
exec "$ROOT_DIR/script/build_and_run.sh" --build-only
