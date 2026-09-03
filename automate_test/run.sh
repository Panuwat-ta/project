#!/usr/bin/env bash
set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

MODE="${1:-all}"
shift || true

# auto setup venv ถ้ายังไม่มี pytest
if [ ! -x venv/bin/pytest ]; then
  bash scripts/setup.sh
fi
source venv/bin/activate

mkdir -p reports/html reports/coverage

run_api() {
  echo "=== API tests ==="
  pytest tests/api -v "$@"
}
run_e2e() {
  echo "=== E2E tests ==="
  pytest tests/e2e -v "$@"
}
run_mobile() {
  echo "=== Mobile bridge ==="
  pytest tests/mobile -v "$@"
}
run_all() {
  echo "=== ALL (api + e2e) ==="
  pytest tests/api tests/e2e -v "$@"
}

case "$MODE" in
  api) run_api "$@" ;;
  e2e) run_e2e "$@" ;;
  mobile) run_mobile "$@" ;;
  all) run_all "$@" ;;
  perf)
    USERS="${1:-10}"
    echo "=== Locust perf: $USERS users, host=$BASE_URL ==="
    locust -f tests/performance/locustfile.py --headless -u "$USERS" -r 5 --run-time 30s --host "${BASE_URL:-http://localhost:8000}"
    ;;
  *) echo "usage: ./run.sh [all|api|e2e|mobile|perf] [pytest args]"; exit 1 ;;
esac

echo ""
echo "Reports: reports/html/report.html  junit: reports/junit.xml  coverage: reports/coverage/index.html"
