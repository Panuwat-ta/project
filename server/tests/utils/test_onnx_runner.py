"""Tests for the ONNX spawn adapter. No model files, GPU, or DB needed."""
import base64
import json
import subprocess

from app.core.config import settings
from app.utils import onnx_runner
from app.utils.onnx_runner import build_worker_env, run_onnx_worker, worker_path


class FakePopen:
    """Records spawn args; replays canned stdout/returncode."""

    instances = []

    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs
        self.killed = False
        self.returncode = 0
        self.stdout_text = ""
        self.stderr_text = ""
        self.timeout_on_first = False
        FakePopen.instances.append(self)

    def communicate(self, input=None, timeout=None):
        if self.timeout_on_first:
            self.timeout_on_first = False
            raise subprocess.TimeoutExpired(cmd="worker", timeout=timeout or 0)
        return self.stdout_text.encode(), self.stderr_text.encode()

    def kill(self):
        self.killed = True


def _ok_process(payload: dict, *args, noise=("[worker] loading model",), **kwargs):
    p = FakePopen(*args, **kwargs)
    lines = list(noise) + [json.dumps(payload)]
    p.stdout_text = "\n".join(lines)
    return p


def test_build_worker_env_carries_model_and_tiling(monkeypatch):
    monkeypatch.setenv("ONNX_MODEL_PATH", "should-be-overridden")
    env = build_worker_env("/models/x.onnx")
    assert env["ONNX_MODEL_PATH"] == "/models/x.onnx"
    assert env["ONNX_TILE_SIZE"] == str(settings.ONNX_TILE_SIZE)
    assert env["ONNX_TILE_OVERLAP"] == str(settings.ONNX_TILE_OVERLAP)
    assert env.get("CUDA_VISIBLE_DEVICES", "non-empty") != ""


def test_run_parses_last_line_and_records_env(monkeypatch):
    FakePopen.instances.clear()
    payload = {"visual_risk_score": 42}

    def factory(*a, **k):
        return _ok_process(payload, *a, **k)

    run = run_onnx_worker(b"IMG", "/models/x.onnx", timeout=5, popen_cls=factory)
    assert run["returncode"] == 0
    assert run["stdout_json"] == payload
    assert run["timed_out"] is False
    assert run["latency_ms"] >= 0

    proc = FakePopen.instances[-1]
    assert proc.args[0][1] == worker_path()
    assert proc.kwargs["env"]["ONNX_MODEL_PATH"] == "/models/x.onnx"
    sent = proc.kwargs  # communicate input checked below via fresh instance
    assert sent["env"]["ONNX_TILE_SIZE"] == str(settings.ONNX_TILE_SIZE)


def test_run_sends_b64_stdin():
    seen = {}

    class Rec(FakePopen):
        def communicate(self, input=None, timeout=None):
            seen["input"] = input
            return self.stdout_text.encode(), b""

    proc_holder = {}

    def factory(*a, **k):
        p = Rec(*a, **k)
        p.stdout_text = json.dumps({"visual_risk_score": 1})
        proc_holder["p"] = p
        return p

    run_onnx_worker(b"RAW", "/m.onnx", popen_cls=factory)
    assert base64.b64decode(seen["input"]) == b"RAW"


def test_timeout_kills_and_reports():
    def factory(*a, **k):
        p = FakePopen(*a, **k)
        p.timeout_on_first = True
        p.returncode = -9
        return p

    run = run_onnx_worker(b"IMG", "/m.onnx", timeout=0.01, popen_cls=factory)
    assert run["timed_out"] is True
    assert run["stdout_json"] is None
    assert FakePopen.instances[-1].killed is True


def test_failure_surfaces_stderr():
    def factory(*a, **k):
        p = FakePopen(*a, **k)
        p.returncode = 1
        p.stderr_text = "boom happened"
        return p

    run = run_onnx_worker(b"IMG", "/m.onnx", popen_cls=factory)
    assert run["returncode"] == 1
    assert run["stdout_json"] is None
    assert run["stderr_text"] == "boom happened"

def test_success_with_empty_stdout_is_reported_without_raising():
    def factory(*a, **k):
        p = FakePopen(*a, **k)
        p.returncode = 0
        p.stdout_text = ""
        return p

    run = run_onnx_worker(b"IMG", "/m.onnx", popen_cls=factory)
    assert run["returncode"] == 0
    assert run["stdout_json"] is None
    assert "empty stdout" in run["stderr_text"]


def test_success_with_malformed_json_is_reported_without_raising():
    def factory(*a, **k):
        p = FakePopen(*a, **k)
        p.returncode = 0
        p.stdout_text = "worker noise\nnot-json"
        return p

    run = run_onnx_worker(b"IMG", "/m.onnx", popen_cls=factory)
    assert run["returncode"] == 0
    assert run["stdout_json"] is None
    assert "Invalid ONNX worker stdout" in run["stderr_text"]
