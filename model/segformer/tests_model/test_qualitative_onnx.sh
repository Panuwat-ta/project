#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SEGFORMER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PYTHON="${SEGFORMER_ROOT}/venv/bin/python"

export MPLCONFIGDIR="${MPLCONFIGDIR:-/tmp/matplotlib-scamguard}"

mapfile -t VERSIONS < <(
    "${PYTHON}" -c '
import json
from pathlib import Path
import sys

manifest = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for entry in manifest["versions"]:
    print(entry["version"])
' "${SCRIPT_DIR}/evaluation_manifest.json"
)

if (( ${#VERSIONS[@]} == 0 )); then
    echo "No model versions found in evaluation_manifest.json" >&2
    exit 1
fi

for version in "${VERSIONS[@]}"; do
    test_script="${SCRIPT_DIR}/v/${version}/test_qualitative_onnx.py"
    echo "Running qualitative ONNX test: ${version}"
    "${PYTHON}" "${test_script}"
done

echo "All qualitative ONNX tests completed successfully."
