#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEGFORMER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SEGFORMER_ROOT}/venv/bin/python"
REGISTER_SCRIPT="${SCRIPT_DIR}/add-v-mode.sh"

export MPLCONFIGDIR="${MPLCONFIGDIR:-/tmp/matplotlib-scamguard}"

if (( $# > 0 )); then
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        printf '%s\n' \
            "Interactive model-version registration" \
            "" \
            "Usage: ./tests_model/add.sh" \
            "" \
            "The script asks for version, checkpoint, ONNX, training log," \
            "training run ID, common-test log, and test run ID."
        exit 0
    fi
    echo "add.sh does not accept arguments; run it without options." >&2
    exit 2
fi

if [[ ! -x "${PYTHON}" ]]; then
    echo "Python environment not found: ${PYTHON}" >&2
    exit 1
fi

if [[ ! -x "${REGISTER_SCRIPT}" ]]; then
    echo "Registration script is not executable: ${REGISTER_SCRIPT}" >&2
    exit 1
fi

ask_required() {
    local variable_name="$1"
    local prompt="$2"
    local default_value="${3:-}"
    local input=""

    while true; do
        if [[ -n "${default_value}" ]]; then
            printf '%s [%s]: ' "${prompt}" "${default_value}"
        else
            printf '%s: ' "${prompt}"
        fi
        if ! IFS= read -r input; then
            printf '\nCancelled.\n'
            exit 130
        fi
        if [[ -z "${input}" ]]; then
            input="${default_value}"
        fi
        if [[ -n "${input}" ]]; then
            printf -v "${variable_name}" '%s' "${input}"
            return
        fi
        echo "A value is required."
    done
}

SUGGESTED_VERSION="$(
    "${PYTHON}" - "${SCRIPT_DIR}/evaluation_manifest.json" <<'PY'
import json
import re
import sys
from pathlib import Path

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
versions = []
for entry in manifest["versions"]:
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", entry["version"])
    if match:
        versions.append(tuple(int(value) for value in match.groups()))
if not versions:
    print("v1.0.0")
else:
    major, minor, patch = max(versions)
    print(f"v{major}.{minor}.{patch + 1}")
PY
)"

printf '\nAdd a new SegFormer model version\n'
printf 'Values in brackets are defaults; press Enter to accept them.\n\n'

ask_required VERSION "1/7 Model version" "${SUGGESTED_VERSION}"
if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version '${VERSION}'; expected format such as v1.0.6" >&2
    exit 2
fi

VERSION_TOKEN="${VERSION//./_}"
ask_required CHECKPOINT "2/7 Checkpoint path"
ask_required ONNX_MODEL "3/7 ONNX model path" "work_dirs/${VERSION}/segformer_${VERSION_TOKEN}_dynamic.onnx"
ask_required TRAINING_RUN_ID "4/7 Training run ID"
ask_required TRAINING_LOG "5/7 Training log path" "work_dirs/${VERSION}/${TRAINING_RUN_ID}/vis_data/scalars.json"
ask_required TEST_RUN_ID "6/7 Common-test run ID"
ask_required TEST_LOG "7/7 Common-test log path" "work_dirs/${VERSION}/test_eval/${TEST_RUN_ID}/${TEST_RUN_ID}.log"

printf '\nPlease review:\n'
printf '  Version:         %s\n' "${VERSION}"
printf '  Checkpoint:      %s\n' "${CHECKPOINT}"
printf '  ONNX model:      %s\n' "${ONNX_MODEL}"
printf '  Training run ID: %s\n' "${TRAINING_RUN_ID}"
printf '  Training log:    %s\n' "${TRAINING_LOG}"
printf '  Test run ID:     %s\n' "${TEST_RUN_ID}"
printf '  Test log:        %s\n\n' "${TEST_LOG}"

read -r -p "Register this model version? [y/N] " reply
if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
    echo "Cancelled; no files changed."
    exit 0
fi

"${REGISTER_SCRIPT}" \
    --version "${VERSION}" \
    --checkpoint "${CHECKPOINT}" \
    --onnx-model "${ONNX_MODEL}" \
    --training-log "${TRAINING_LOG}" \
    --training-run-id "${TRAINING_RUN_ID}" \
    --test-log "${TEST_LOG}" \
    --test-run-id "${TEST_RUN_ID}" \
    --yes
