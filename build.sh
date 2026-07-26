#!/usr/bin/env bash
# build.sh — one-shot build + run + optional dist for Clipper.
# Usage:
#   ./build.sh          build debug and launch
#   ./build.sh dist     release build + dmg → dist/Clipper.dmg
#   ./build.sh stop     quit the running app
set -euo pipefail
cd "$(dirname "$0")"

case "${1:-run}" in
  dist) exec scripts/driver.sh dist ;;
  stop) exec scripts/driver.sh stop ;;
  run)
    scripts/driver.sh build
    scripts/driver.sh run
    ;;
  *)
    echo "usage: build.sh [run|dist|stop]"
    exit 1
    ;;
esac
