"""SegFormer Det Head (Track B, plan.md หัวข้อ 32-33).

หัว image-level classifier ต่อบน backbone feature 4 stages โดยไม่แตะ
`library/` (vendored mmseg) และไม่แตะ config หลัก:

- DetHead: GAP แยก stage + concat + Linear(1024 -> 1) ได้ det logit ระดับภาพ
- backbone + seg head แช่แข็งเสมอ เทรนแค่ DetHead (~1K params)
- DetSegWrapper: forward ครั้งเดียวได้ (seg_logits, det_logit) ใช้ตอน export ONNX
"""
from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

# mit_b2 embed_dims ตาม configs/segformer_mit-b2-*.py
STAGE_CHANNELS = (64, 128, 320, 512)


def pool_stage_features(feats) -> torch.Tensor:
    """GAP feature 4 stages แล้ว concat เป็น vector 1024 มิติต่อภาพ.

    ฟังก์ชันนี้ใช้ร่วมกันทั้ง online training/inference และ feature cache เพื่อให้
    vector ที่ cache มีความหมายตรงกับ DetHead เดิมทุกประการ.
    """
    pooled = [F.adaptive_avg_pool2d(f, 1).flatten(1) for f in feats]
    return torch.cat(pooled, dim=1)


class DetHead(nn.Module):
    """v1 linear image-level head: GAP 4 stages -> Linear(1024,1)."""

    arch = "linear"

    def __init__(self, in_channels: int = sum(STAGE_CHANNELS)) -> None:
        super().__init__()
        self.in_channels = in_channels
        self.fc = nn.Linear(in_channels, 1)

    def forward_pooled(self, pooled: torch.Tensor) -> torch.Tensor:
        """Forward จาก cached pooled feature shape ``(N, 1024)``."""
        return self.fc(pooled)

    def forward(self, feats) -> torch.Tensor:
        return self.forward_pooled(pool_stage_features(feats))


class MLPDetHead(nn.Module):
    """v2 MLP head for richer nonlinear image-level decision boundaries."""

    arch = "mlp"

    def __init__(self, in_channels: int = sum(STAGE_CHANNELS), dropout: float = 0.2) -> None:
        super().__init__()
        self.in_channels = in_channels
        self.dropout = float(dropout)
        self.net = nn.Sequential(
            nn.LayerNorm(in_channels),
            nn.Linear(in_channels, 256),
            nn.GELU(),
            nn.Dropout(self.dropout),
            nn.Linear(256, 64),
            nn.GELU(),
            nn.Dropout(self.dropout),
            nn.Linear(64, 1),
        )

    def forward_pooled(self, pooled: torch.Tensor) -> torch.Tensor:
        return self.net(pooled)

    def forward(self, feats) -> torch.Tensor:
        return self.forward_pooled(pool_stage_features(feats))


def build_det_head(arch: str = "linear", dropout: float = 0.2) -> nn.Module:
    if arch == "linear":
        return DetHead()
    if arch == "mlp":
        return MLPDetHead(dropout=dropout)
    raise ValueError(f"unknown Det Head arch: {arch}")


def freeze_seg(model: torch.nn.Module) -> torch.nn.Module:
    """แช่ backbone + decode_head ทั้งหมด เหลือแค่ DetHead ที่เทรนได้."""
    for name, p in model.named_parameters():
        p.requires_grad = False
    return model


def build_seg_model(config: str, checkpoint: str, device: str = "cpu"):
    """สร้าง mmseg EncoderDecoder จาก config+checkpoint (ใช้ init_model เดิม)."""
    from mmseg.apis import init_model
    model = init_model(config, checkpoint, device=device)
    return model


class DetSegWrapper(nn.Module):
    """Wrapper สำหรับ export ONNX 2 outputs: (seg_logits, det_logit).

    เทียบเท่า _forward เดิมของ segmentor (extract_feat ครั้งเดียว) บวก det head
    """

    def __init__(self, model: torch.nn.Module, det_head: DetHead) -> None:
        super().__init__()
        self.model = model
        self.det_head = det_head

    def forward(self, inputs: torch.Tensor):
        feats = self.model.extract_feat(inputs)
        seg_logits = self.model.decode_head.forward(feats)
        det_logit = self.det_head(feats)
        return seg_logits, det_logit


def save_det(det_head: DetHead, path: str, meta: dict | None = None) -> None:
    payload = {"state_dict": det_head.state_dict(), "meta": meta or {}}
    torch.save(payload, path)


def load_det(path: str, device: str = "cpu") -> nn.Module:
    payload = torch.load(path, map_location=device, weights_only=False)
    meta = payload.get("meta", {})
    arch = meta.get("det_arch", "linear")
    dropout = float(meta.get("dropout", 0.2))
    head = build_det_head(arch=arch, dropout=dropout)
    head.load_state_dict(payload["state_dict"])
    return head.to(device)
