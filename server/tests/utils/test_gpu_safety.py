import pytest

from app.utils.gpu_safety import parse_nvidia_smi_memory, should_defer_xai_gpu


def test_gpu_preflight_defers_when_capacity_or_telemetry_is_unsafe():
    assert should_defer_xai_gpu(-1, [(4096, 3800)]) is True
    assert should_defer_xai_gpu(-1, [(8192, 1200)]) is True
    assert should_defer_xai_gpu(-1, []) is True
    assert should_defer_xai_gpu(-1, [(8192, 0)]) is True


def test_gpu_preflight_defers_when_any_visible_gpu_is_unsafe():
    assert should_defer_xai_gpu(-1, [(24576, 23000), (4096, 3500)]) is True


def test_gpu_preflight_allows_verified_headroom_or_explicit_cpu_mode():
    assert should_defer_xai_gpu(-1, [(8192, 4000), (24576, 23000)]) is False
    assert should_defer_xai_gpu(0, []) is False


def test_nvidia_smi_parser_returns_every_visible_gpu():
    assert parse_nvidia_smi_memory("4096, 3500\n24576, 23000\n") == [
        (4096, 3500),
        (24576, 23000),
    ]


@pytest.mark.parametrize("output", ["", "not available", "8192, 0"])
def test_nvidia_smi_parser_rejects_unusable_telemetry(output):
    with pytest.raises((ValueError, TypeError)):
        parse_nvidia_smi_memory(output)
