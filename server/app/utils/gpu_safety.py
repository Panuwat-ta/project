XAI_MIN_SAFE_TOTAL_VRAM_MB = 4097
XAI_MIN_FREE_VRAM_MB = 1500


def parse_nvidia_smi_memory(output: str) -> list[tuple[int, int]]:
    """Return total/free MiB for every visible GPU from nvidia-smi output."""
    gpu_memory = []
    for line in output.splitlines():
        if not line.strip():
            continue
        fields = [field.strip() for field in line.split(",")]
        if len(fields) != 2:
            raise ValueError("unexpected nvidia-smi memory output")

        total_vram_mb, free_vram_mb = (int(field) for field in fields)
        if total_vram_mb <= 0 or free_vram_mb <= 0:
            raise ValueError("nvidia-smi returned non-positive memory values")
        gpu_memory.append((total_vram_mb, free_vram_mb))

    if not gpu_memory:
        raise ValueError("nvidia-smi returned no GPU memory rows")
    return gpu_memory


def should_defer_xai_gpu(
    target_gpu_layers: int,
    gpu_memory: list[tuple[int, int]],
) -> bool:
    if target_gpu_layers == 0:
        return False
    if not gpu_memory:
        return True
    return any(
        total_vram_mb <= 0
        or free_vram_mb <= 0
        or total_vram_mb < XAI_MIN_SAFE_TOTAL_VRAM_MB
        or free_vram_mb < XAI_MIN_FREE_VRAM_MB
        for total_vram_mb, free_vram_mb in gpu_memory
    )
