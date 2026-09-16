#!/bin/bash
# Admin Portal QA loop runner. See skill `admin-portal-qa`.
# Exit 0 only when every gate passes; exit 1 otherwise. Never prints secrets.
set -u

PROJECT=/home/panuwat/project
ROOT=$PROJECT/admin-portal
LOOP=$ROOT/.impeccable/qa-loop
# Serialize overlapping runs (cron + manual + verifier): skip, don't fail.
exec 9>"$LOOP/.lock"
if ! flock -n 9; then
  echo "SKIP: another QA run is in progress."
  exit 2
fi
RUN_ID=$(date +%Y%m%d-%H%M%S)
OUT=$LOOP/runs/$RUN_ID.json
mkdir -p "$LOOP/runs"
cd "$ROOT" || exit 1

pass=0; fail=0
declare -A results durations

run_gate() {
  local name="$1" timeout_s="$2"
  shift 2
  local start end detail rc
  start=$(date +%s)
  detail=$(timeout "${timeout_s}s" "$@" 2>&1 | tail -c 2000; exit "${PIPESTATUS[0]}")
  rc=$?
  end=$(date +%s)
  durations[$name]=$((end - start))
  if [ $rc -eq 0 ]; then
    results[$name]="PASS"
    pass=$((pass + 1))
  else
    # One retry, then record.
    sleep 2
    detail=$(timeout "${timeout_s}s" "$@" 2>&1 | tail -c 2000; exit "${PIPESTATUS[0]}")
    rc=$?
    end=$(date +%s)
    durations[$name]=$((end - start))
    if [ $rc -eq 0 ]; then
      results[$name]="PASS-after-retry"
      pass=$((pass + 1))
    else
      results[$name]="FAIL"
      fail=$((fail + 1))
      printf '%s\n' "$detail" > "$LOOP/runs/$RUN_ID-$name.log"
    fi
  fi
}

# Gate 0: clean-tree guard (no auto-stash, ever).
if [ -n "$(git -C "$PROJECT" status --porcelain -- admin-portal/src)" ]; then
  results[clean_tree]="FAIL-dirty"
  fail=$((fail + 1))
  echo "dirty-tree" > "$LOOP/runs/$RUN_ID-clean_tree.log"
else
  results[clean_tree]="PASS"
  pass=$((pass + 1))
fi
durations[clean_tree]=0

run_gate lint 180 npm run lint --silent
run_gate tests 600 npm run test:run --silent
run_gate build 300 npm run build --silent

# Gate 4a: chunk-size budget (no JS chunk over 500 kB uncompressed).
big=$(find "$ROOT/dist/assets" -name '*.js' -size +500k 2>/dev/null | head -5)
if [ -z "$big" ]; then
  results[chunks]="PASS"; pass=$((pass + 1))
else
  results[chunks]="FAIL"; fail=$((fail + 1))
  printf '%s\n' "$big" > "$LOOP/runs/$RUN_ID-chunks.log"
fi
durations[chunks]=0

run_gate live_contracts 180 node "$LOOP/scripts/live-contract-check.mjs"

overall="PASS"
[ $fail -gt 0 ] && overall="FAIL"

python3 - "$OUT" "$RUN_ID" "$overall" "$pass" "$fail" "${results[clean_tree]}" "${durations[clean_tree]}" \
  "${results[lint]}" "${durations[lint]}" "${results[tests]}" "${durations[tests]}" \
  "${results[build]}" "${durations[build]}" "${results[chunks]}" "${durations[chunks]}" \
  "${results[live_contracts]}" "${durations[live_contracts]}" << 'EOF'
import json, sys
_, out, run_id, overall, passed, failed, *rest = sys.argv
names = ['clean_tree', 'lint', 'tests', 'build', 'chunks', 'live_contracts']
gates = {}
for i, name in enumerate(names):
    gates[name] = {'result': rest[i * 2], 'duration_s': int(rest[i * 2 + 1])}
with open(out, 'w') as f:
    json.dump({'run_id': run_id, 'overall': overall, 'passed': int(passed),
               'failed': int(failed), 'gates': gates}, f, indent=1)
EOF

# Rewrite the Last-run block in STATE.md; append failures to Triage inbox.
python3 - "$LOOP/STATE.md" "$RUN_ID" "$overall" "$fail" << 'EOF'
import re, sys
_, state_path, run_id, overall, fail_count = sys.argv
text = open(state_path).read()
block = f"Last run: {run_id} — {overall} (failed gates: {fail_count})"
text = re.sub(r'Last run:.*', block, text, count=1)
if int(fail_count) > 0:
    text = text.replace('## Triage inbox\n',
                        f"## Triage inbox\n\n- [ ] {run_id}: {overall} — see runs/{run_id}.json", 1)
open(state_path, 'w').write(text)
EOF

# Consecutive-failure pause rule (quality gates only; dirty-tree is informational).
if [ "$overall" = "FAIL" ]; then
  streak=$(python3 -c "
import json, glob
files = sorted(glob.glob('$LOOP/runs/*.json'))[-3:]
streak = 0
for f in reversed(files):
    gates = json.load(open(f))['gates']
    if any(gates[g]['result'] != 'PASS' and not gates[g]['result'].startswith('PASS') for g in ['lint', 'tests', 'build', 'chunks', 'live_contracts']):
        streak += 1
    else:
        break
print(streak)")
  if [ "$streak" -ge 3 ]; then
    python3 - "$LOOP/STATE.md" << 'EOF'
import sys
text = open(sys.argv[1]).read().replace('paused: false', 'paused: true')
open(sys.argv[1], 'w').write(text)
EOF
    echo "LOOP PAUSED after 3 consecutive failures — human reset required."
  fi
fi

echo "QA run $RUN_ID: $overall (pass=$pass fail=$fail)"
[ "$overall" = "PASS" ]
