#!/usr/bin/env bash
set -euo pipefail

MODE="full"
if [[ ${1-} == "fast" ]]; then
  MODE="fast"
fi

RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; NC="\033[0m"

log() { echo -e "${YELLOW}[verify]${NC} $*"; }
ok() { echo -e "${GREEN}[ok]${NC} $*"; }
err() { echo -e "${RED}[fail]${NC} $*"; }

log "Flutter analyze..."
if ! flutter analyze; then
  err "flutter analyze failed"
  exit 1
fi
ok "Analyze passed"

log "Running tests ($MODE mode)..."
if [[ "$MODE" == "fast" ]]; then
  # Fast mode: run only service + widget smoke tests (adjust pattern if more granularity needed)
  if ! flutter test test/services/rolling_stats_service_test.dart test/widget_test.dart; then
    err "Fast tests failed"
    exit 1
  fi
else
  if ! flutter test; then
    err "Full test suite failed"
    exit 1
  fi
fi
ok "Tests passed"

log "Deprecation scan (withOpacity) ..."
WITH_OPACITY_COUNT=$(grep -R "withOpacity(" -n lib || true | wc -l | tr -d ' ')
if [[ "$WITH_OPACITY_COUNT" != "0" ]]; then
  log "Found $WITH_OPACITY_COUNT usages of deprecated withOpacity (consider replacing)."
fi

ok "All pre-commit checks succeeded."
