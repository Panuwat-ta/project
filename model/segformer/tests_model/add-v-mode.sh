#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEGFORMER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SEGFORMER_ROOT}/venv/bin/python"
PROJECT_ROOT="$(cd "${SEGFORMER_ROOT}/../.." && pwd)"
ONNX_TEST_PYTHON="${PROJECT_ROOT}/server/venv/bin/python"

export MPLCONFIGDIR="${MPLCONFIGDIR:-/tmp/matplotlib-scamguard}"

usage() {
    cat <<'EOF'
Register a new SegFormer model version and regenerate its evaluation report.

Usage:
  ./tests_model/add-v-mode.sh \
    --version v1.0.6 \
    --checkpoint work_dirs/v1.0.6/best_mIoU_iter_200000.pth \
    --onnx-model work_dirs/v1.0.6/segformer_v1_0_6_dynamic.onnx \
    --training-log work_dirs/v1.0.6/TRAIN_RUN/vis_data/scalars.json \
    --training-run-id TRAIN_RUN \
    --test-log work_dirs/v1.0.6/test_eval/TEST_RUN/TEST_RUN.log \
    --test-run-id TEST_RUN

Options:
  --yes    Skip the confirmation prompt.
  --help   Show this help.

All artifact paths must be inside model/segformer. The test log must contain a
complete locked common-test run and complete background/forgery metrics.
EOF
}

VERSION=""
CHECKPOINT=""
ONNX_MODEL=""
TRAINING_LOG=""
TRAINING_RUN_ID=""
TEST_LOG=""
TEST_RUN_ID=""
ASSUME_YES=0

while (( $# > 0 )); do
    case "$1" in
        --version) VERSION="${2:-}"; shift 2 ;;
        --checkpoint) CHECKPOINT="${2:-}"; shift 2 ;;
        --onnx-model) ONNX_MODEL="${2:-}"; shift 2 ;;
        --training-log) TRAINING_LOG="${2:-}"; shift 2 ;;
        --training-run-id) TRAINING_RUN_ID="${2:-}"; shift 2 ;;
        --test-log) TEST_LOG="${2:-}"; shift 2 ;;
        --test-run-id) TEST_RUN_ID="${2:-}"; shift 2 ;;
        --yes) ASSUME_YES=1; shift ;;
        --help|-h) usage; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for required in VERSION CHECKPOINT ONNX_MODEL TRAINING_LOG TRAINING_RUN_ID TEST_LOG TEST_RUN_ID; do
    if [[ -z "${!required}" ]]; then
        echo "Missing required option for ${required}" >&2
        usage >&2
        exit 2
    fi
done

if [[ ! -x "${ONNX_TEST_PYTHON}" ]]; then
    echo "ONNX test environment not found: ${ONNX_TEST_PYTHON}" >&2
    exit 1
fi

if [[ ! "${VERSION}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid version '${VERSION}'; expected format such as v1.0.6" >&2
    exit 2
fi

printf 'New model version:\n'
printf '  Version:         %s\n' "${VERSION}"
printf '  Checkpoint:      %s\n' "${CHECKPOINT}"
printf '  ONNX model:      %s\n' "${ONNX_MODEL}"
printf '  Training log:    %s\n' "${TRAINING_LOG}"
printf '  Training run ID: %s\n' "${TRAINING_RUN_ID}"
printf '  Test log:        %s\n' "${TEST_LOG}"
printf '  Test run ID:     %s\n' "${TEST_RUN_ID}"

if (( ASSUME_YES == 0 )); then
    read -r -p "Validate and register this version? [y/N] " reply
    if [[ ! "${reply}" =~ ^[Yy]$ ]]; then
        echo "Cancelled; no files changed."
        exit 0
    fi
fi

"${PYTHON}" - \
    "${SEGFORMER_ROOT}" \
    "${SCRIPT_DIR}" \
    "${VERSION}" \
    "${CHECKPOINT}" \
    "${ONNX_MODEL}" \
    "${TRAINING_LOG}" \
    "${TRAINING_RUN_ID}" \
    "${TEST_LOG}" \
    "${TEST_RUN_ID}" <<'PY'
import json
import os
import re
import sys
import tempfile
from pathlib import Path

import numpy as np

(
    segformer_root_text,
    tests_root_text,
    version,
    checkpoint_text,
    onnx_text,
    training_log_text,
    training_run_id,
    test_log_text,
    test_run_id,
) = sys.argv[1:]

segformer_root = Path(segformer_root_text).resolve()
tests_root = Path(tests_root_text).resolve()
manifest_path = tests_root / "evaluation_manifest.json"
report_root = tests_root / "report"
sys.path.insert(0, str(report_root))

import plot_training  # noqa: E402


def normalize_artifact(path_text: str) -> tuple[str, Path]:
    candidate = Path(path_text)
    path = candidate.resolve() if candidate.is_absolute() else (segformer_root / candidate).resolve()
    if not path.is_relative_to(segformer_root):
        raise SystemExit(f"Artifact escapes SegFormer root: {path}")
    if not path.is_file():
        raise SystemExit(f"Artifact does not exist: {path}")
    return path.relative_to(segformer_root).as_posix(), path


checkpoint, checkpoint_path = normalize_artifact(checkpoint_text)
onnx_model, _ = normalize_artifact(onnx_text)
training_log, training_log_path = normalize_artifact(training_log_text)
test_log, test_log_path = normalize_artifact(test_log_text)

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
if any(entry["version"] == version for entry in manifest["versions"]):
    raise SystemExit(f"Version is already registered: {version}")

expected_batches = int(manifest["dataset"]["test_batches"])
training = plot_training.load_training_log(training_log_path)
test = plot_training.load_test_log(test_log_path, expected_batches)

validation = training["validation"]
best_index = int(np.argmax(validation["mIoU"]))
best_iter = int(validation["step"][best_index])
checkpoint_match = re.search(r"iter_(\d+)", checkpoint_path.name)
if checkpoint_match and int(checkpoint_match.group(1)) != best_iter:
    raise SystemExit(
        f"Checkpoint iteration {checkpoint_match.group(1)} does not match "
        f"best validation iteration {best_iter}"
    )

entry = {
    "version": version,
    "checkpoint": checkpoint,
    "onnx_model": onnx_model,
    "training_log": training_log,
    "training_run_id": training_run_id,
    "test_log": test_log,
    "test_run_id": test_run_id,
    "expected_common_test": {
        "mIoU": test["mIoU"],
        "mDice": test["mDice"],
        "forgery_IoU": test["classes"]["forgery"]["IoU"],
        "forgery_Dice": test["classes"]["forgery"]["Dice"],
    },
}
manifest["versions"].append(entry)
plot_training.validate_manifest_data(manifest, root=segformer_root, check_files=True)

version_dir = tests_root / "v" / version
wrapper_path = version_dir / "test_qualitative_onnx.py"
if wrapper_path.exists():
    raise SystemExit(f"Version test script already exists: {wrapper_path}")
version_dir.mkdir(parents=True, exist_ok=True)

wrapper = f'''#!/usr/bin/env python3
"""Run the {version} qualitative ONNX example."""
from pathlib import Path
import sys

REPORT_ROOT = Path(__file__).resolve().parents[2] / "report"
sys.path.insert(0, str(REPORT_ROOT))

from plot_training import render_qualitative_onnx_version  # noqa: E402


if __name__ == "__main__":
    for output in render_qualitative_onnx_version("{version}"):
        print(output)
'''

with tempfile.NamedTemporaryFile(
    "w", encoding="utf-8", dir=version_dir, delete=False
) as wrapper_file:
    wrapper_file.write(wrapper)
    wrapper_temp = Path(wrapper_file.name)

with tempfile.NamedTemporaryFile(
    "w", encoding="utf-8", dir=manifest_path.parent, delete=False
) as manifest_file:
    json.dump(manifest, manifest_file, indent=2, ensure_ascii=False)
    manifest_file.write("\n")
    manifest_temp = Path(manifest_file.name)

os.chmod(wrapper_temp, 0o755)
os.replace(wrapper_temp, wrapper_path)
os.replace(manifest_temp, manifest_path)

metrics = entry["expected_common_test"]
print(f"Registered {version} in {manifest_path}")
print(f"Created {wrapper_path}")
print(
    "Common test: "
    f"mIoU={metrics['mIoU']:.2f}, mDice={metrics['mDice']:.2f}, "
    f"forgery IoU={metrics['forgery_IoU']:.2f}, "
    f"forgery Dice={metrics['forgery_Dice']:.2f}"
)
PY

"${PYTHON}" -m unittest "${SCRIPT_DIR}/report/test_plot_training.py"
"${ONNX_TEST_PYTHON}" -m unittest "${SCRIPT_DIR}/report/test_onnx_models.py"
"${SCRIPT_DIR}/test.sh"

echo "Added ${VERSION} successfully."
echo "Review and update tests_model/report/reportmodel.md before any deployment change."
