"""Export the selected SegFormer checkpoint to an ONNX model.

Run from this directory after activating the environment that contains
PyTorch, MMSegmentation, onnx and onnxruntime.
"""

from __future__ import annotations

import argparse
from pathlib import Path

import onnx
import torch
from mmseg.apis import init_model


ROOT_DIR = Path(__file__).resolve().parent
DEFAULT_CONFIG = ROOT_DIR / "work_dirs/v1.0.0/segformer_mit-b2-v2.py"
DEFAULT_CHECKPOINT = ROOT_DIR / "work_dirs/v1.0.0/best_mIoU_iter_112000.pth"
DEFAULT_OUTPUT = ROOT_DIR / "work_dirs/v1.0.0/segformer_v1.onnx"


class ONNXWrapper(torch.nn.Module):
    """Expose only the model tensor output for ONNX Runtime."""

    def __init__(self, model: torch.nn.Module) -> None:
        super().__init__()
        self.model = model

    def forward(self, inputs: torch.Tensor) -> torch.Tensor:
        # ``tensor`` mode returns segmentation logits, without MMSeg post-processing.
        return self.model(inputs, data_samples=None, mode="tensor")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Export SegFormer to ONNX")
    parser.add_argument("--config", type=Path, default=DEFAULT_CONFIG)
    parser.add_argument("--checkpoint", type=Path, default=DEFAULT_CHECKPOINT)
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument("--height", type=int, default=512)
    parser.add_argument("--width", type=int, default=512)
    parser.add_argument("--opset", type=int, default=17)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    for path, label in ((args.config, "config"), (args.checkpoint, "checkpoint")):
        if not path.is_file():
            raise FileNotFoundError(f"ไม่พบ {label}: {path}")

    # Export on CPU so the generated ONNX file is portable to CPU or GPU runtime.
    model = init_model(str(args.config), str(args.checkpoint), device="cpu")
    wrapped_model = ONNXWrapper(model).eval()
    dummy_input = torch.randn(1, 3, args.height, args.width, dtype=torch.float32)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    torch.onnx.export(
        wrapped_model,
        dummy_input,
        str(args.output),
        input_names=["input"],
        output_names=["logits"],
        opset_version=args.opset,
        do_constant_folding=True,
    )

    onnx_model = onnx.load(str(args.output))
    onnx.checker.check_model(onnx_model)
    print(f"Export สำเร็จและตรวจสอบแล้ว: {args.output}")
    print(f"Input: [1, 3, {args.height}, {args.width}] (normalized RGB, NCHW)")


if __name__ == "__main__":
    main()
