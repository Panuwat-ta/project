"""Export SegFormer checkpoint to a DYNAMIC-SIZE ONNX model.

The static 512x512 model loses detail when input is downscaled (the true
accuracy bottleneck identified in review). SegFormer's backbone is
resolution-agnostic (conv PatchEmbed, no absolute pos_embed), so the SAME
weights can be exported with dynamic height/width axes. One model then
accepts any input resolution; the worker chooses a target size per image.

Usage (from this directory, in the segformer env):
    python export_onnx_dynamic.py --height 1024 --width 1024
"""

from __future__ import annotations

import argparse
import ctypes
from pathlib import Path

import onnx
import torch
from mmseg.apis import init_model

# torch.export triggers loading of libbz2 during tracing; preload to avoid ImportError
try:
    ctypes.CDLL("/lib64/libbz2.so.1", mode=ctypes.RTLD_GLOBAL)
except Exception as e:
    print(f"[warn] could not preload libbz2: {e}")

ROOT_DIR = Path(__file__).resolve().parent


class ONNXWrapper(torch.nn.Module):
    """Expose only the model tensor output for ONNX Runtime."""

    def __init__(self, model: torch.nn.Module) -> None:
        super().__init__()
        self.model = model

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        return self.model(inputs, data_samples=None, mode="tensor")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export SegFormer to dynamic-size ONNX")
    parser.add_argument("--config", type=Path, required=True, help="Path to config file")
    parser.add_argument("--checkpoint", type=Path, required=True, help="Path to .pth checkpoint")
    parser.add_argument("--output", type=Path, required=True, help="Output .onnx path")
    parser.add_argument("--height", type=int, default=1024)
    parser.add_argument("--width", type=int, default=1024)
    parser.add_argument("--opset", type=int, default=17)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    for path, label in ((args.config, "config"), (args.checkpoint, "checkpoint")):
        if not path.is_file():
            raise FileNotFoundError(f"ไม่พบ {label}: {path}")

    model = init_model(str(args.config), str(args.checkpoint), device="cpu")
    wrapped_model = ONNXWrapper(model).eval()
    dummy_input = torch.randn(1, 3, args.height, args.width, dtype=torch.float32)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with torch.no_grad():
        torch.onnx.export(
            wrapped_model,
            dummy_input,
            str(args.output),
            input_names=["input"],
            output_names=["logits"],
            dynamic_axes={
                "input": {2: "height", 3: "width"},
                "logits": {2: "height_out", 3: "width_out"},
            },
            opset_version=args.opset,
            do_constant_folding=True,
        )

    onnx_model = onnx.load(str(args.output))
    onnx.checker.check_model(onnx_model)
    print(f"Export สำเร็จและตรวจสอบแล้ว: {args.output}")
    print(f"Input: [1, 3, height, width] (normalized RGB, NCHW) — dynamic H/W")


if __name__ == "__main__":
    main()
