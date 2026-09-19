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


class DetHead(nn.Module):
    """Image-level forgery head: GAP per stage + concat + linear."""

    def __init__(self, in_channels: int = sum(STAGE_CHANNELS)) -> None:
        super().__init__()
        self.in_channels = in_channels
        self.fc = nn.Linear(in_channels, 1)

    def forward(self, feats) -> torch.Tensor:
        pooled = [F.adaptive_avg_pool2d(f, 1).flatten(1) for f in feats]
        x = torch.cat(pooled, dim=1)
        return self.fc(x)  # (N, 1) logit, ยังไม่ผ่าน sigmoid


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


def load_det(path: str, device: str = "cpu") -> DetHead:
    head = DetHead()
    payload = torch.load(path, map_location=device, weights_only=False)
    head.load_state_dict(payload["state_dict"])
    return head
