"""Det5 local/patch image-level heads on frozen SegFormer v1.0.6 features."""
from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

STAGE_CHANNELS = (64, 128, 320, 512)
GRID_SIZE = 4
TOKEN_DIM = sum(STAGE_CHANNELS)
NUM_TOKENS = GRID_SIZE * GRID_SIZE


def local_stage_tokens(feats, grid_size: int = GRID_SIZE) -> torch.Tensor:
    """Align four stages to a grid and return B x (G*G) x 1024 local tokens.

    See the ONNX dynamic-axes limitation documented in
    ``det6_local.local_stage_tokens``: a fixed grid cannot be exported with a
    working dynamic grid, so the ONNX det output is only valid at the traced size.
    """
    tokens = []
    for feat in feats:
        pooled = F.adaptive_avg_pool2d(feat, (grid_size, grid_size))
        pooled = pooled.flatten(2).transpose(1, 2)
        tokens.append(pooled)
    return torch.cat(tokens, dim=-1)


class PatchAttentionHead(nn.Module):
    arch = "patch_attention"

    def __init__(self, token_dim: int = TOKEN_DIM, num_tokens: int = NUM_TOKENS,
                 hidden: int = 128, dropout: float = 0.2) -> None:
        super().__init__()
        self.token_dim = int(token_dim)
        self.num_tokens = int(num_tokens)
        self.hidden = int(hidden)
        self.dropout = float(dropout)
        self.norm = nn.LayerNorm(self.token_dim)
        self.project = nn.Sequential(
            nn.Linear(self.token_dim, self.hidden),
            nn.GELU(),
            nn.Dropout(self.dropout),
        )
        self.pos_embed = nn.Parameter(torch.zeros(1, self.num_tokens, self.hidden))
        nn.init.trunc_normal_(self.pos_embed, std=0.02)
        self.attn = nn.Linear(self.hidden, 1)
        self.classifier = nn.Sequential(
            nn.LayerNorm(self.hidden),
            nn.Linear(self.hidden, 64),
            nn.GELU(),
            nn.Dropout(self.dropout),
            nn.Linear(64, 1),
        )

    def forward_tokens(self, tokens: torch.Tensor) -> torch.Tensor:
        if tokens.ndim != 3 or tokens.shape[1] != self.num_tokens:
            raise ValueError(f"expected Bx{self.num_tokens}x{self.token_dim}, got {tuple(tokens.shape)}")
        z = self.project(self.norm(tokens)) + self.pos_embed
        weights = torch.softmax(self.attn(z), dim=1)
        pooled = (weights * z).sum(dim=1)
        return self.classifier(pooled)

    def forward(self, feats) -> torch.Tensor:
        return self.forward_tokens(local_stage_tokens(feats))


class PatchTopKHead(nn.Module):
    arch = "patch_topk"
    def __init__(self, token_dim: int = TOKEN_DIM, topk: int = 4,
                 hidden: int = 128, dropout: float = 0.2) -> None:
        super().__init__()
        self.token_dim = int(token_dim)
        self.topk = int(topk)
        self.hidden = int(hidden)
        self.dropout = float(dropout)
        self.scorer = nn.Sequential(
            nn.LayerNorm(self.token_dim),
            nn.Linear(self.token_dim, self.hidden),
            nn.GELU(),
            nn.Dropout(self.dropout),
            nn.Linear(self.hidden, 1),
        )

    def forward_tokens(self, tokens: torch.Tensor) -> torch.Tensor:
        patch_logits = self.scorer(tokens).squeeze(-1)
        k = min(self.topk, patch_logits.shape[1])
        values = torch.topk(patch_logits, k=k, dim=1).values
        return values.mean(dim=1, keepdim=True)

    def forward(self, feats) -> torch.Tensor:
        return self.forward_tokens(local_stage_tokens(feats))


def build_det5_head(arch: str, dropout: float = 0.2,
                    topk: int = 4) -> nn.Module:
    if arch == "patch_attention":
        return PatchAttentionHead(dropout=dropout)
    if arch == "patch_topk":
        return PatchTopKHead(dropout=dropout, topk=topk)
    raise ValueError(f"unknown Det5 arch: {arch}")


def save_det5(head: nn.Module, path: str, meta: dict | None = None) -> None:
    payload = {"state_dict": head.state_dict(), "meta": meta or {}}
    torch.save(payload, path)


def load_det5(path: str, device: str = "cpu") -> nn.Module:
    payload = torch.load(path, map_location=device, weights_only=False)
    meta = payload.get("meta", {})
    head = build_det5_head(
        meta.get("det_arch", "patch_attention"),
        dropout=float(meta.get("dropout", 0.2)),
        topk=int(meta.get("topk", 4)),
    )
    head.load_state_dict(payload["state_dict"])
    return head.to(device)


class Det5SegWrapper(nn.Module):
    """Future export wrapper: segmentation logits + Det5 image logit."""

    def __init__(self, model: nn.Module, det_head: nn.Module) -> None:
        super().__init__()
        self.model = model
        self.det_head = det_head

    def forward(self, inputs: torch.Tensor):
        feats = self.model.extract_feat(inputs)
        seg_logits = self.model.decode_head.forward(feats)
        det_logit = self.det_head(feats)
        return seg_logits, det_logit
