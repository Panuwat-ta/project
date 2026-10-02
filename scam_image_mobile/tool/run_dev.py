#!/usr/bin/env python3
"""Run the Android development app without loading or bundling the full .env."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlsplit

APP_DIR = Path(__file__).resolve().parents[1]


class DevConfigError(ValueError):
    """Raised when the local development API configuration is unsafe or invalid."""


def load_api_base_url(env_file: Path) -> str:
    """Read and validate only API_BASE_URL from a dotenv-style file."""
    try:
        content = env_file.read_text(encoding="utf-8-sig")
    except OSError as error:
        raise DevConfigError("Could not read the requested environment file") from error

    values: list[str] = []
    for line_number, raw_line in enumerate(content.splitlines(), start=1):
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[len("export ") :].lstrip()

        key, separator, raw_value = line.partition("=")
        if key.strip() != "API_BASE_URL":
            continue
        if not separator:
            raise DevConfigError(f"API_BASE_URL has no value on line {line_number}")

        value = raw_value.strip()
        if value.startswith(("'", '"')):
            quote = value[0]
            closing_quote = value.find(quote, 1)
            if closing_quote < 0:
                raise DevConfigError(f"API_BASE_URL has invalid quoting on line {line_number}")
            trailing_text = value[closing_quote + 1 :].strip()
            if trailing_text and not trailing_text.startswith("#"):
                raise DevConfigError(f"API_BASE_URL has invalid quoting on line {line_number}")
            value = value[1:closing_quote]
        else:
            value = value.split(" #", maxsplit=1)[0].rstrip()
        values.append(value.strip())

    if len(values) != 1 or not values[0]:
        raise DevConfigError("Environment file must define API_BASE_URL exactly once")

    value = values[0]
    if any(character.isspace() for character in value):
        raise DevConfigError("API_BASE_URL must not contain whitespace")
    try:
        parsed = urlsplit(value)
        hostname = parsed.hostname
        _ = parsed.port
    except ValueError as error:
        raise DevConfigError("API_BASE_URL is not a valid HTTP(S) URL") from error

    if (
        parsed.scheme not in {"http", "https"}
        or not hostname
        or parsed.username is not None
        or parsed.password is not None
        or parsed.query
        or parsed.fragment
        or parsed.path.rstrip("/") != "/api/v1"
    ):
        raise DevConfigError(
            "API_BASE_URL must be an HTTP(S) API v1 URL without credentials, query or fragment"
        )

    return value.rstrip("/")


def build_flutter_command(api_base_url: str, flutter_args: list[str]) -> list[str]:
    """Build a dev-only command and prevent callers from replacing its config."""
    for index, argument in enumerate(flutter_args):
        if argument == "--release":
            raise DevConfigError("The development runner does not allow --release")
        if argument == "--dart-define-from-file" or argument.startswith(
            "--dart-define-from-file="
        ):
            raise DevConfigError("The development runner does not load define files")

        definition = ""
        if argument.startswith("--dart-define="):
            definition = argument.split("=", maxsplit=1)[1]
        elif argument == "--dart-define" and index + 1 < len(flutter_args):
            definition = flutter_args[index + 1]

        key = definition.partition("=")[0]
        if key in {"APP_ENV", "API_BASE_URL"}:
            raise DevConfigError(f"The development runner controls {key}")

    return [
        "flutter",
        "run",
        "--dart-define=APP_ENV=development",
        f"--dart-define=API_BASE_URL={api_base_url}",
        *flutter_args,
    ]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--env-file",
        type=Path,
        default=APP_DIR / ".env",
        help="dotenv-style file; only API_BASE_URL is read",
    )
    parser.add_argument(
        "--check-config",
        action="store_true",
        help="validate API_BASE_URL without starting Flutter or printing its value",
    )
    parser.add_argument("flutter_args", nargs=argparse.REMAINDER)
    args = parser.parse_args(argv)

    flutter_args = list(args.flutter_args)
    if flutter_args[:1] == ["--"]:
        flutter_args.pop(0)
    if args.check_config and flutter_args:
        parser.error("Flutter arguments cannot be combined with --check-config")

    try:
        api_base_url = load_api_base_url(args.env_file.expanduser().resolve())
        if args.check_config:
            print("Development API configuration is valid.")
            return 0
        command = build_flutter_command(api_base_url, flutter_args)
    except DevConfigError as error:
        print(f"run_dev: {error}", file=sys.stderr)
        return 2

    try:
        return subprocess.run(command, cwd=APP_DIR, check=False).returncode
    except FileNotFoundError:
        print("run_dev: Flutter was not found on PATH", file=sys.stderr)
        return 127


if __name__ == "__main__":
    raise SystemExit(main())
