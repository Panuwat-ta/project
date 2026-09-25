"""Compare the exact v1.0.8 checkpoint with its ONNX export using two venvs."""
import argparse
from pathlib import Path

import numpy as np


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['torch', 'ort'])
    parser.add_argument('--config', required=True)
    parser.add_argument('--checkpoint', required=True)
    parser.add_argument('--onnx', required=True)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    shapes = [(256, 256), (320, 448)]

    if args.mode == 'torch':
        import torch
        from mmseg.apis import init_model

        torch.set_num_threads(2)
        model = init_model(args.config, args.checkpoint, device='cpu')
        for height, width in shapes:
            tensor = np.random.default_rng(height * 1000 + width).normal(
                size=(1, 3, height, width)).astype(np.float32)
            with torch.no_grad():
                logits = model(torch.from_numpy(tensor), data_samples=None,
                               mode='tensor').numpy()
            np.save(args.output_dir / f'input_{height}x{width}.npy', tensor)
            np.save(args.output_dir / f'torch_{height}x{width}.npy', logits)
            print(f'PyTorch {height}x{width}: {logits.shape}', flush=True)
        return

    import onnxruntime as ort

    session = ort.InferenceSession(args.onnx, providers=['CPUExecutionProvider'])
    assert len(session.get_inputs()) == 1 and len(session.get_outputs()) == 1
    name = session.get_inputs()[0].name
    for height, width in shapes:
        tensor = np.load(args.output_dir / f'input_{height}x{width}.npy')
        ref = np.load(args.output_dir / f'torch_{height}x{width}.npy')
        got = session.run(None, {name: tensor})[0]
        assert got.shape == ref.shape and np.isfinite(got).all()
        diff = np.abs(ref - got)
        mismatch = np.mean(ref.argmax(axis=1) != got.argmax(axis=1)) * 100
        print(f'ONNX {height}x{width}: max_abs={diff.max():.8f}, '
              f'mean_abs={diff.mean():.8f}, argmax_mismatch_pct={mismatch:.6f}',
              flush=True)
        assert diff.max() < 0.001 and mismatch < 0.1
    print('PyTorch/ONNX parity: PASS', flush=True)


if __name__ == '__main__':
    main()
