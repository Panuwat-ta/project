"""Det Head aggregation variants for the local-token caches (Det5/Det6 shape).

Motivation is the measured result of 2026-09-29, not a guess. On the protected
real-camera diagnostic (camera9) the ranking was:

    det2b  global GAP 1024-D        specificity 33.33%
    det6a  local 8x8, 64 tokens      specificity 22.22%
    det5a  local 4x4, 16 tokens      specificity 11.11%

More local tokens did not help, so the discriminative signal for the Authentic
domain looks global rather than local. These variants keep the 64 local tokens
but reduce them to global statistics before classification, which is the cheap
way to test that hypothesis without recomputing a feature cache.

Result: the hypothesis was not supported. None of these four heads beat the
local-attention control on camera9; see
Det-Head/search_runs/2026-09-29/REPORT.md.
"""
from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

STAGE_CHANNELS = (64, 128, 320, 512)
TOKEN_DIM = sum(STAGE_CHANNELS)


def _mlp(in_dim: int, hidden: int, out_dim: int, dropout: float) -> nn.Sequential:
    return nn.Sequential(
        nn.LayerNorm(in_dim),
        nn.Linear(in_dim, hidden),
        nn.GELU(),
        nn.Dropout(dropout),
        nn.Linear(hidden, out_dim),
    )


class TokenStatsHead(nn.Module):
    """Reduce local tokens to global mean/max/std statistics, then classify.

    ``arch = "token_stats"``. The three pooled statistics are concatenated, so
    the classifier sees how the per-token distribution is shaped (mean = overall
    level, max = strongest local response, std = dispersion) instead of relying
    on a single learned attention weighting.
    """

    arch = "token_stats"

    def __init__(self, token_dim: int = TOKEN_DIM, hidden: int = 128,
                 dropout: float = 0.2) -> None:
        super().__init__()
        self.token_dim = int(token_dim)
        self.norm = nn.LayerNorm(self.token_dim)
        self.net = _mlp(self.token_dim * 3, hidden, 1, dropout)

    def forward_tokens(self, tokens: torch.Tensor) -> torch.Tensor:
        z = self.norm(tokens)
        stats = torch.cat([z.mean(dim=1), z.amax(dim=1), z.std(dim=1)], dim=-1)
        return self.net(stats)

    def forward(self, feats) -> torch.Tensor:
        from det6_local import local_stage_tokens
        return self.forward_tokens(local_stage_tokens(feats, grid_size=8))


class TokenStatsTopKHead(nn.Module):
    """Global statistics of the top-k local tokens by a learned patch score.

    ``arch = "token_stats_topk"``. Keeps the Det5 top-k intuition (forgery
    evidence is usually local and sparse) but classifies from global statistics
    of those tokens rather than from the raw per-token logits.
    """

    arch = "token_stats_topk"

    def __init__(self, token_dim: int = TOKEN_DIM, hidden: int = 128,
                 dropout: float = 0.2, topk: int = 4) -> None:
        super().__init__()
        self.token_dim = int(token_dim)
        self.topk = int(topk)
        self.norm = nn.LayerNorm(self.token_dim)
        self.scorer = _mlp(self.token_dim, hidden, 1, dropout)
        self.net = _mlp(self.token_dim * 3, hidden, 1, dropout)

    def forward_tokens(self, tokens: torch.Tensor) -> torch.Tensor:
        z = self.norm(tokens)
        score = self.scorer(z).squeeze(-1)
        k = min(self.topk, score.shape[1])
        idx = torch.topk(score, k=k, dim=1).indices
        picked = torch.gather(z, 1, idx.unsqueeze(-1).expand(-1, -1, z.shape[-1]))
        stats = torch.cat([picked.mean(dim=1), picked.amax(dim=1), picked.std(dim=1)], dim=-1)
        return self.net(stats)

    def forward(self, feats) -> torch.Tensor:
        from det6_local import local_stage_tokens
        return self.forward_tokens(local_stage_tokens(feats, grid_size=8))


class SpatialPyramidHead(nn.Module):
    """Average-pool the 8x8 token grid down to 1x1/2x2/4x4 and concatenate.

    ``arch = "spatial_pyramid"``. This is the explicit interpolation between
    det2b (1 token, best on camera9) and det6a (64 tokens), built from tokens
    that are already cached, so no new precompute is required.
    """

    arch = "spatial_pyramid"

    def __init__(self, token_dim: int = TOKEN_DIM, hidden: int = 128,
                 dropout: float = 0.2) -> None:
        super().__init__()
        self.token_dim = int(token_dim)
        self.grid = 8
        self.norm = nn.LayerNorm(self.token_dim)
        # 1x1 -> 1, 2x2 -> 4, 4x4 -> 16
        self.net = _mlp(self.token_dim * 21, hidden, 1, dropout)

    def forward_tokens(self, tokens: torch.Tensor) -> torch.Tensor:
        if tokens.shape[1] != self.grid * self.grid:
            raise ValueError(f"expected {self.grid * self.grid} tokens, got {tokens.shape[1]}")
        z = self.norm(tokens)
        grid = z.transpose(1, 2).reshape(z.shape[0], self.token_dim, self.grid, self.grid)
        parts = [F.adaptive_avg_pool2d(grid, s).flatten(1) for s in (1, 2, 4)]
        return self.net(torch.cat(parts, dim=-1))

    def forward(self, feats) -> torch.Tensor:
        from det6_local import local_stage_tokens
        return self.forward_tokens(local_stage_tokens(feats, grid_size=8))


class TokenStatsCoarseHead(nn.Module):
    """Global statistics computed on a coarse 2x2 pooling of the 8x8 tokens.

    ``arch = "token_stats_coarse"``. Same reduction as ``token_stats`` but each
    token is first averaged over its 4x4 neighbourhood, which suppresses
    single-token noise before the statistics are taken.
    """

    arch = "token_stats_coarse"

    def __init__(self, token_dim: int = TOKEN_DIM, hidden: int = 128,
                 dropout: float = 0.2) -> None:
        super().__init__()
        self.token_dim = int(token_dim)
        self.grid = 8
        self.coarse = 2
        self.norm = nn.LayerNorm(self.token_dim)
        self.net = _mlp(self.token_dim * 3, hidden, 1, dropout)

    def forward_tokens(self, tokens: torch.Tensor) -> torch.Tensor:
        z = self.norm(tokens)
        grid = z.transpose(1, 2).reshape(z.shape[0], self.token_dim, self.grid, self.grid)
        z = F.adaptive_avg_pool2d(grid, self.coarse).flatten(2).transpose(1, 2)
        stats = torch.cat([z.mean(dim=1), z.amax(dim=1), z.std(dim=1)], dim=-1)
        return self.net(stats)

    def forward(self, feats) -> torch.Tensor:
        from det6_local import local_stage_tokens
        return self.forward_tokens(local_stage_tokens(feats, grid_size=8))


ARCHS = {
    "token_stats": TokenStatsHead,
    "token_stats_topk": TokenStatsTopKHead,
    "spatial_pyramid": SpatialPyramidHead,
    "token_stats_coarse": TokenStatsCoarseHead,
}


def build_variant(arch: str, dropout: float = 0.2, topk: int = 4) -> nn.Module:
    if arch not in ARCHS:
        raise ValueError(f"unknown variant arch: {arch}; known={sorted(ARCHS)}")
    if arch == "token_stats_topk":
        return ARCHS[arch](dropout=dropout, topk=topk)
    return ARCHS[arch](dropout=dropout)


def save_variant(head: nn.Module, path: str, meta: dict | None = None) -> None:
    torch.save({"state_dict": head.state_dict(), "meta": meta or {}}, path)


def load_variant(path: str, device: str = "cpu") -> nn.Module:
    payload = torch.load(path, map_location=device, weights_only=False)
    meta = payload.get("meta", {})
    head = build_variant(meta.get("det_arch", "token_stats"),
                         dropout=float(meta.get("dropout", 0.2)),
                         topk=int(meta.get("topk", 4)))
    head.load_state_dict(payload["state_dict"])
    return head.to(device)
