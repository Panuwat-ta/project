#!/usr/bin/env python3
"""Plot SegFormer training logs v1.0.0-v1.0.4 to PNG maps and evaluation benchmarks.

Reads: ../work_dirs/<ver>/<run>/vis_data/scalars.json (JSON lines)
       train rows: loss (+decode.loss_ce/dice), lr @ iter | val rows: mIoU/mDice/mAcc/aAcc @ step
       report/reportmodel.md section 2 (documented real-world benchmark)
       tests_model/img/test1.jpg + work_dirs/v1.0.0/segformer_v1_0_0_dynamic.onnx (test evaluation)
Writes: figs/<ver>_loss.png (with LR schedule twin-axis, EMA, early zoom inset)
        figs/<ver>_metrics.png
        figs/compare_miou.png, figs/best_miou_bar.png
        figs/compare_mdice.png, figs/best_mdice_bar.png
        figs/compare_loss.png
        figs/documented_benchmark.png, figs/test_benchmark_documented.png
        figs/test_evaluation_onnx.png
        figs/summary.csv
Usage: /tmp/plotvenv/bin/python report/plot_training.py  (run from segformer dir)
"""
import csv
import json
import subprocess
import tempfile
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from PIL import Image

BASE = Path(__file__).resolve().parent
WORK = BASE.parent / "work_dirs"
FIGS = BASE / "figs"
FIGS.mkdir(exist_ok=True)

VERSIONS = {
    "v1.0.0": "20260717_205331",
    "v1.0.1": "20260808_051906",
    "v1.0.2": "20260809_133842",
    "v1.0.3": "20260810_175651",
    "v1.0.4": "20260814_062529",
}
COLORS = {
    "v1.0.0": "tab:blue",
    "v1.0.1": "tab:orange",
    "v1.0.2": "tab:green",
    "v1.0.3": "tab:red",
    "v1.0.4": "tab:purple",
}


def compute_ema(values, weight=0.9):
    """Compute debiased exponential moving average."""
    if not values:
        return []
    ema = []
    c = 0.0
    for i, v in enumerate(values):
        c = weight * c + (1.0 - weight) * v
        debias = 1.0 - (weight ** (i + 1))
        ema.append(c / debias if debias > 0 else c)
    return ema


def load(ver):
    train_x, loss, ce, dice, lr = [], [], [], [], []
    val_x, miou, mdice, macc, aacc = [], [], [], [], []
    scalars_file = WORK / ver / VERSIONS[ver] / "vis_data" / "scalars.json"
    with open(scalars_file) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            r = json.loads(line)
            if "mIoU" in r:
                val_x.append(r.get("step", r.get("iter", 0)))
                miou.append(r["mIoU"])
                mdice.append(r.get("mDice"))
                macc.append(r.get("mAcc"))
                aacc.append(r.get("aAcc"))
            elif "loss" in r:
                train_x.append(r.get("iter", r.get("step", 0)))
                loss.append(r["loss"])
                ce.append(r.get("decode.loss_ce"))
                dice.append(r.get("decode.loss_dice"))
                lr.append(r.get("lr"))
    return dict(
        train=(train_x, loss, ce, dice, lr),
        val=(val_x, miou, mdice, macc, aacc),
    )


def plot_loss(ver, tx, loss, ce, dice, lr):
    loss_ema = compute_ema(loss, weight=0.9)
    fig, ax = plt.subplots(figsize=(9.5, 5))
    ax.plot(tx, loss, label="loss (raw)", color=COLORS[ver], lw=0.6, alpha=0.3)
    ax.plot(tx, loss_ema, label="loss (EMA)", color=COLORS[ver], lw=1.6)
    if any(c is not None for c in ce):
        valid_ce = [c if c is not None else 0.0 for c in ce]
        ax.plot(tx, valid_ce, label="loss_ce", lw=0.8, alpha=0.6, color="tab:green")
    if any(d is not None for d in dice):
        valid_dice = [d if d is not None else 0.0 for d in dice]
        ax.plot(tx, valid_dice, label="loss_dice", lw=0.8, alpha=0.6, color="tab:orange")
    ax.set_title(f"{ver} — training loss with LR schedule & EMA")
    ax.set_xlabel("iter")
    ax.set_ylabel("loss")
    ax.grid(alpha=0.3)

    # (a) LR schedule twin-axis overlay
    ax2 = ax.twinx()
    valid_lr = [l if l is not None else 0.0 for l in lr]
    ax2.plot(tx, valid_lr, label="learning rate (LR)", color="crimson", lw=1.0, linestyle="--", alpha=0.7)
    ax2.set_ylabel("learning rate", color="crimson")
    ax2.tick_params(axis="y", labelcolor="crimson")
    ax2.ticklabel_format(style="scientific", scilimits=(0, 0), axis="y")

    # (b) Early-phase zoom inset
    early_cutoff = 10000
    early_idx = [i for i, x in enumerate(tx) if x <= early_cutoff]
    if len(early_idx) > 1:
        axins = ax.inset_axes([0.48, 0.40, 0.35, 0.46])
        sub_tx = [tx[i] for i in early_idx]
        sub_loss = [loss[i] for i in early_idx]
        sub_ema = [loss_ema[i] for i in early_idx]
        axins.plot(sub_tx, sub_loss, color=COLORS[ver], lw=0.6, alpha=0.35)
        axins.plot(sub_tx, sub_ema, color=COLORS[ver], lw=1.4)
        axins.set_title(f"Early-phase Zoom (iter ≤ {early_cutoff//1000}k)", fontsize=8)
        axins.tick_params(labelsize=7)
        axins.grid(alpha=0.2)
        ax.indicate_inset_zoom(axins, edgecolor="gray", alpha=0.5)

    h1, l1 = ax.get_legend_handles_labels()
    h2, l2 = ax2.get_legend_handles_labels()
    ax.legend(h1 + h2, l1 + l2, loc="upper left", fontsize=8)
    fig.tight_layout()
    fig.savefig(FIGS / f"{ver}_loss.png", dpi=120)
    plt.close(fig)


def plot_metrics(ver, vx, miou, mdice, aacc, bi):
    fig, ax = plt.subplots(figsize=(9, 4.5))
    ax.plot(vx, miou, marker="o", ms=3, label="mIoU", color=COLORS[ver])
    if any(d is not None for d in mdice):
        ax.plot(vx, mdice, marker="s", ms=3, label="mDice", alpha=0.8, color="tab:cyan")
    if any(a is not None for a in aacc):
        ax.plot(vx, aacc, marker="^", ms=2.5, label="aAcc", alpha=0.6, color="tab:olive")
    ax.scatter(
        [vx[bi]], [miou[bi]], s=80, zorder=5, color="crimson",
        label=f"best mIoU {miou[bi]:.2f}% @ {vx[bi]}"
    )
    ax.set_title(f"{ver} — validation metrics")
    ax.set_xlabel("iter")
    ax.set_ylabel("%")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(FIGS / f"{ver}_metrics.png", dpi=120)
    plt.close(fig)


def plot_comparisons(data, summary, order):
    # mIoU comparison
    fig, ax = plt.subplots(figsize=(10, 5))
    for ver in order:
        vx, miou = data[ver]["val"][0], data[ver]["val"][1]
        ax.plot(vx, miou, marker="o", ms=3, label=ver, color=COLORS[ver])
    ax.set_title("mIoU comparison v1.0.0–v1.0.4")
    ax.set_xlabel("iter")
    ax.set_ylabel("mIoU %")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(FIGS / "compare_miou.png", dpi=120)
    plt.close(fig)

    # Best mIoU bar chart
    fig, ax = plt.subplots(figsize=(8, 4.5))
    bars = ax.bar(order, [summary[v]["miou"] for v in order], color=[COLORS[v] for v in order])
    ax.bar_label(bars, fmt="%.2f")
    ax.set_title("Best validation mIoU per version")
    ax.set_ylabel("mIoU %")
    fig.tight_layout()
    fig.savefig(FIGS / "best_miou_bar.png", dpi=120)
    plt.close(fig)

    # (c) mDice comparison across versions
    fig, ax = plt.subplots(figsize=(10, 5))
    for ver in order:
        vx, mdice = data[ver]["val"][0], data[ver]["val"][2]
        ax.plot(vx, mdice, marker="s", ms=3, label=ver, color=COLORS[ver])
    ax.set_title("mDice comparison v1.0.0–v1.0.4")
    ax.set_xlabel("iter")
    ax.set_ylabel("mDice %")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(FIGS / "compare_mdice.png", dpi=120)
    plt.close(fig)

    # Best mDice bar chart
    fig, ax = plt.subplots(figsize=(8, 4.5))
    bars = ax.bar(order, [summary[v]["mdice"] for v in order], color=[COLORS[v] for v in order])
    ax.bar_label(bars, fmt="%.2f")
    ax.set_title("Best validation mDice per version")
    ax.set_ylabel("mDice %")
    fig.tight_layout()
    fig.savefig(FIGS / "best_mdice_bar.png", dpi=120)
    plt.close(fig)

    # Loss comparison across versions with EMA
    fig, ax = plt.subplots(figsize=(10, 5))
    for ver in order:
        tx, loss = data[ver]["train"][0], data[ver]["train"][1]
        loss_ema = compute_ema(loss, weight=0.9)
        ax.plot(tx, loss_ema, label=f"{ver} (EMA)", color=COLORS[ver], lw=1.2)
    ax.set_title("Training Loss Comparison (EMA smoothed) v1.0.0–v1.0.4")
    ax.set_xlabel("iter")
    ax.set_ylabel("loss")
    ax.legend()
    ax.grid(alpha=0.3)
    fig.tight_layout()
    fig.savefig(FIGS / "compare_loss.png", dpi=120)
    plt.close(fig)


def plot_documented_benchmark():
    """Plot documented real-world benchmark table from report/reportmodel.md section 2."""
    scenarios = [
        "Photoshop Splicing\n(server/tests/test1.png)",
        "Complex Montage\n(tests_model/img/test1.jpg)",
        "Authentic Natural\n(Natural Landscape)",
    ]
    v100_scores = [98.47, 83.24, 2.75]
    v104_scores = [20.52, 43.07, 3.36]

    x = np.arange(len(scenarios))
    w = 0.35

    fig, ax = plt.subplots(figsize=(10, 5.5))
    bars1 = ax.bar(x - w / 2, v100_scores, w, label="v1.0.0 (Production)", color=COLORS["v1.0.0"])
    bars2 = ax.bar(x + w / 2, v104_scores, w, label="v1.0.4 (Defacto Multi-Dataset)", color=COLORS["v1.0.4"])

    ax.axhline(70, color="crimson", linestyle="--", alpha=0.6, label="High Risk Threshold (70%)")
    ax.axhline(40, color="goldenrod", linestyle=":", alpha=0.6, label="Medium Risk Threshold (40%)")

    ax.bar_label(bars1, fmt="%.2f%%", padding=3, fontweight="bold")
    ax.bar_label(bars2, fmt="%.2f%%", padding=3)

    ax.set_ylabel("Forgery Confidence / Visual Score (%)")
    ax.set_title(
        "Real-World Benchmark Evaluation [DOCUMENTED BENCHMARK]\n"
        "Source: report/reportmodel.md §2 (2-Class Softmax)",
        fontsize=11,
    )
    ax.set_xticks(x)
    ax.set_xticklabels(scenarios)
    ax.set_ylim(0, 118)
    ax.legend(loc="upper right")
    ax.grid(axis="y", alpha=0.3)
    fig.tight_layout()
    fig.savefig(FIGS / "documented_benchmark.png", dpi=120)
    fig.savefig(FIGS / "test_benchmark_documented.png", dpi=120)
    plt.close(fig)


def run_test_evaluation():
    """Run test evaluation on tests_model/img/test1.jpg with v1.0.0 ONNX model."""
    img_path = BASE.parent / "tests_model" / "img" / "test1.jpg"
    model_path = WORK / "v1.0.0" / "segformer_v1_0_0_dynamic.onnx"

    if not img_path.exists() or not model_path.exists():
        print(f"[INFO] Image or ONNX model path not found ({img_path}, {model_path})")
        return

    heatmap = None
    # 1. Try direct onnxruntime import
    try:
        import onnxruntime as ort
        img = Image.open(img_path).convert("RGB")
        w, h = img.size
        arr = np.array(img).astype(np.float32)
        mean = np.array([123.675, 116.28, 103.53], dtype=np.float32)
        std = np.array([58.395, 57.12, 57.375], dtype=np.float32)
        norm = (arr - mean) / std
        tensor = np.transpose(norm, (2, 0, 1))[None, :, :, :].astype(np.float32)

        sess = ort.InferenceSession(str(model_path), providers=["CPUExecutionProvider"])
        logits = sess.run(None, {"input": tensor})[0]
        exp = np.exp(logits - np.max(logits, axis=1, keepdims=True))
        prob = exp / np.sum(exp, axis=1, keepdims=True)
        forgery_prob = prob[0, 1, :, :]
        prob_img = Image.fromarray((forgery_prob * 255).astype(np.uint8))
        heatmap = np.array(prob_img.resize((w, h), Image.Resampling.BILINEAR)).astype(np.float32) / 255.0
    except ImportError:
        # 2. Check for server venv python with onnxruntime
        server_py = BASE.parent.parent.parent / "server" / "venv" / "bin" / "python"
        if server_py.exists():
            with tempfile.NamedTemporaryFile(suffix=".npy", delete=False) as tmp_f:
                tmp_npy = tmp_f.name
            code = (
                "import onnxruntime as ort, numpy as np, sys\n"
                "from PIL import Image\n"
                "m_path, i_path, out_npy = sys.argv[1], sys.argv[2], sys.argv[3]\n"
                "img = Image.open(i_path).convert('RGB')\n"
                "w, h = img.size\n"
                "arr = np.array(img).astype(np.float32)\n"
                "norm = (arr - np.array([123.675, 116.28, 103.53], dtype=np.float32)) / np.array([58.395, 57.12, 57.375], dtype=np.float32)\n"
                "tensor = np.transpose(norm, (2, 0, 1))[None, :, :, :].astype(np.float32)\n"
                "sess = ort.InferenceSession(m_path, providers=['CPUExecutionProvider'])\n"
                "logits = sess.run(None, {'input': tensor})[0]\n"
                "exp = np.exp(logits - np.max(logits, axis=1, keepdims=True))\n"
                "prob = (exp / np.sum(exp, axis=1, keepdims=True))[0, 1, :, :]\n"
                "prob_img = Image.fromarray((prob * 255).astype(np.uint8))\n"
                "resized = np.array(prob_img.resize((w, h), Image.Resampling.BILINEAR)).astype(np.float32) / 255.0\n"
                "np.save(out_npy, resized)\n"
            )
            res = subprocess.run(
                [str(server_py), "-c", code, str(model_path), str(img_path), tmp_npy],
                capture_output=True,
            )
            if res.returncode == 0 and Path(tmp_npy).exists():
                heatmap = np.load(tmp_npy)
                Path(tmp_npy).unlink(missing_ok=True)
            else:
                print(f"[INFO] Server venv ONNX execution failed: {res.stderr.decode() if res.stderr else ''}")

    if heatmap is None:
        print("[INFO] Live ONNX inference blocked by environment; synthesizing nothing.")
        return

    img = Image.open(img_path).convert("RGB")
    img_arr = np.array(img)

    fig, axes = plt.subplots(1, 3, figsize=(14, 4.5))

    # 1. Original
    axes[0].imshow(img_arr)
    axes[0].set_title(f"Input: {img_path.name}")
    axes[0].axis("off")

    # 2. Predicted Heatmap
    im = axes[1].imshow(heatmap, cmap="jet", vmin=0, vmax=1)
    axes[1].set_title(f"v1.0.0 ONNX Forgery Heatmap\n(Peak: {heatmap.max()*100:.2f}%)")
    axes[1].axis("off")
    cbar = fig.colorbar(im, ax=axes[1], fraction=0.046, pad=0.04)
    cbar.set_label("Forgery Probability")

    # 3. Overlay
    axes[2].imshow(img_arr)
    mask_alpha = (heatmap > 0.4).astype(float) * 0.55
    axes[2].imshow(heatmap, cmap="jet", alpha=mask_alpha, vmin=0, vmax=1)
    axes[2].set_title("Overlay (Threshold > 0.4)")
    axes[2].axis("off")

    plt.suptitle("SegFormer v1.0.0 ONNX Test Evaluation (segformer_v1_0_0_dynamic.onnx)", fontsize=13, y=0.98)
    fig.tight_layout()
    fig.savefig(FIGS / "test_evaluation_onnx.png", dpi=120)
    plt.close(fig)


def save_summary_csv(summary, order):
    """Save summary stats to report/figs/summary.csv."""
    csv_path = FIGS / "summary.csv"
    fieldnames = [
        "version",
        "n_train",
        "n_val",
        "best_iter",
        "mIoU",
        "mDice",
        "mAcc",
        "aAcc",
        "min_loss",
        "final_loss",
    ]
    with open(csv_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for v in order:
            s = summary[v]
            writer.writerow({
                "version": v,
                "n_train": s["n_train"],
                "n_val": s["n_val"],
                "best_iter": s["best_iter"],
                "mIoU": f"{s['miou']:.2f}",
                "mDice": f"{s['mdice']:.2f}",
                "mAcc": f"{s['macc']:.2f}" if s.get("macc") is not None else "",
                "aAcc": f"{s['aacc']:.2f}",
                "min_loss": f"{s['min_loss']:.4f}",
                "final_loss": f"{s['final_loss']:.4f}",
            })


def main():
    data = {v: load(v) for v in VERSIONS}
    summary = {}
    order = list(VERSIONS)

    for ver in order:
        d = data[ver]
        (tx, loss, ce, dice, lr) = d["train"]
        (vx, miou, mdice, macc, aacc) = d["val"]
        bi = max(range(len(miou)), key=lambda i: miou[i])
        summary[ver] = dict(
            n_train=len(tx),
            n_val=len(vx),
            best_iter=vx[bi],
            miou=miou[bi],
            mdice=mdice[bi],
            macc=macc[bi] if any(macc) else None,
            aacc=aacc[bi],
            min_loss=min(loss) if loss else 0.0,
            final_loss=loss[-1] if loss else 0.0,
        )

        # Plot individual training loss with LR twin-axis, EMA, and early zoom
        plot_loss(ver, tx, loss, ce, dice, lr)

        # Plot individual validation metrics
        plot_metrics(ver, vx, miou, mdice, aacc, bi)

    # Plot cross-version comparisons (mIoU, mDice, Loss)
    plot_comparisons(data, summary, order)

    # (d) Test evaluation & documented benchmark
    plot_documented_benchmark()
    run_test_evaluation()

    # (e) Print summary stats and save to CSV
    save_summary_csv(summary, order)

    print(
        f"{'ver':8} {'train':>6} {'val':>4} {'best_iter':>9} "
        f"{'mIoU':>7} {'mDice':>7} {'aAcc':>7} {'min_loss':>9} {'final_loss':>10}"
    )
    for v in order:
        s = summary[v]
        print(
            f"{v:8} {s['n_train']:>6} {s['n_val']:>4} {s['best_iter']:>9} "
            f"{s['miou']:>7.2f} {s['mdice']:>7.2f} {s['aacc']:>7.2f} "
            f"{s['min_loss']:>9.4f} {s['final_loss']:>10.4f}"
        )

    all_pngs = sorted(p.name for p in FIGS.glob("*.png"))
    print(f"Total PNGs generated: {len(all_pngs)}")
    print("figs:", all_pngs)


if __name__ == "__main__":
    main()

