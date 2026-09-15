#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/../../../" && pwd)"
TESTS_MODEL_DIR="$(cd -- "${SCRIPT_DIR}/../tests_model" && pwd)"
PYTHON="${PROJECT_ROOT}/server/venv/bin/python"
MANIFEST="${TESTS_MODEL_DIR}/evaluation_manifest.json"

if [[ ! -x "${PYTHON}" ]]; then
  echo "ERROR: Python environment not found: ${PYTHON}" >&2
  exit 2
fi

VERSION_ARGS=()
if (( $# > 0 )); then
  VERSION_ARGS=(--versions "$@")
fi

echo "[1/4] Core unit tests and local data inventory tests"
(
  cd -- "${SCRIPT_DIR}" || exit 2
  "${PYTHON}" -m unittest -v test_evaluation_core.py test_source_inventory.py
)
unit_status=$?
if (( unit_status != 0 )); then
  exit "${unit_status}"
fi

echo "[2/4] ONNX model contract tests"
(
  cd -- "${TESTS_MODEL_DIR}/report" || exit 2
  "${PYTHON}" -m unittest -v test_onnx_models.py
)
contract_status=$?
if (( contract_status != 0 )); then
  exit "${contract_status}"
fi

quantitative_gate_args=()
if (( $# > 0 )); then
  release_selected=false
  for version in "$@"; do
    if [[ "${version}" == "v1.0.5" ]]; then
      release_selected=true
      break
    fi
  done
  if [[ "${release_selected}" == false ]]; then
    quantitative_gate_args=(--no-release-gate)
  fi
fi

echo "[3/4] Quantitative image/mask evaluation"
"${PYTHON}" "${SCRIPT_DIR}/evaluate_with_masks.py" \
  --manifest "${MANIFEST}" \
  "${VERSION_ARGS[@]}" \
  "${quantitative_gate_args[@]}"
quantitative_status=$?

echo "[4/4] Qualitative original/manipulated rendering"
"${PYTHON}" "${SCRIPT_DIR}/render_qualitative_pairs.py" \
  --manifest "${MANIFEST}" \
  "${VERSION_ARGS[@]}"
qualitative_status=$?

if (( quantitative_status != 0 )); then
  echo "FAILED: quantitative evaluation or v1.0.5 release gate failed." >&2
  exit "${quantitative_status}"
fi
if (( qualitative_status != 0 )); then
  echo "FAILED: qualitative rendering failed." >&2
  exit "${qualitative_status}"
fi

echo "PASS: Test-Case outputs are in ${SCRIPT_DIR}/output"
