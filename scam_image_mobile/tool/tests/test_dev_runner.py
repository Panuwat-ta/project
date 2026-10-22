import sys
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import run_dev
from run_dev import DevConfigError, build_flutter_command, load_api_base_url


APP_DIR = Path(__file__).resolve().parents[2]
VALID_URL = "http://192.0.2.10:8000/api/v1"


class DevelopmentConfigTests(unittest.TestCase):
    def write_env(self, contents):
        temporary_directory = tempfile.TemporaryDirectory(dir=APP_DIR)
        self.addCleanup(temporary_directory.cleanup)
        path = Path(temporary_directory.name) / ".env"
        path.write_text(contents, encoding="utf-8")
        return path

    def test_reads_only_api_base_url_and_ignores_other_values(self):
        path = self.write_env(
            "DATABASE_PASSWORD=must-not-be-read\n"
            "export API_BASE_URL='http://192.0.2.10:8000/api/v1/' # local\n"
            "THIRD_PARTY_KEY=must-not-be-read\n"
        )
        self.assertEqual(load_api_base_url(path), VALID_URL)

    def test_missing_or_duplicate_api_base_url_fails_closed(self):
        for contents in ["OTHER=value\n", "API_BASE_URL=\n", f"API_BASE_URL={VALID_URL}\nAPI_BASE_URL={VALID_URL}\n"]:
            with self.subTest(contents=contents), self.assertRaises(DevConfigError):
                load_api_base_url(self.write_env(contents))

    def test_missing_env_file_fails_closed(self):
        with tempfile.TemporaryDirectory(dir=APP_DIR) as directory:
            missing_file = Path(directory) / ".env"
            with self.assertRaises(DevConfigError):
                load_api_base_url(missing_file)

    def test_invalid_url_shapes_are_rejected(self):
        values = [
            "ftp://192.0.2.10:8000/api/v1",
            "http://user:password@192.0.2.10:8000/api/v1",
            "http://192.0.2.10:8000/api/v1?token=value",
            "http://192.0.2.10:8000/api/v1#fragment",
            "http://192.0.2.10:8000/",
        ]
        for value in values:
            with self.subTest(value=value), self.assertRaises(DevConfigError):
                load_api_base_url(self.write_env(f"API_BASE_URL={value}\n"))


class MainFunctionTests(unittest.TestCase):
    def write_env(self, contents):
        temporary_directory = tempfile.TemporaryDirectory(dir=APP_DIR)
        self.addCleanup(temporary_directory.cleanup)
        path = Path(temporary_directory.name) / ".env"
        path.write_text(contents, encoding="utf-8")
        return path

    def test_check_config_validates_without_launching_flutter_or_printing_url(self):
        env_file = self.write_env(f"API_BASE_URL={VALID_URL}\nOTHER=private-value\n")
        output = StringIO()
        with patch.object(run_dev.subprocess, "run") as flutter, redirect_stdout(output):
            result = run_dev.main(["--env-file", str(env_file), "--check-config"])
        self.assertEqual(result, 0)
        self.assertIn("configuration is valid", output.getvalue())
        self.assertNotIn(VALID_URL, output.getvalue())
        self.assertNotIn("private-value", output.getvalue())
        flutter.assert_not_called()

    def test_launch_passes_only_api_config_and_returns_flutter_status(self):
        env_file = self.write_env(
            f"API_BASE_URL={VALID_URL}\nDATABASE_PASSWORD=private-value\n"
        )
        completed = SimpleNamespace(returncode=7)
        with patch.object(run_dev.subprocess, "run", return_value=completed) as flutter:
            result = run_dev.main(
                ["--env-file", str(env_file), "--", "--profile", "-d", "device-id"]
            )
        self.assertEqual(result, 7)
        flutter.assert_called_once_with(
            [
                "flutter",
                "run",
                "--dart-define=APP_ENV=development",
                f"--dart-define=API_BASE_URL={VALID_URL}",
                "--profile",
                "-d",
                "device-id",
            ],
            cwd=run_dev.APP_DIR,
            check=False,
        )

    def test_invalid_configuration_returns_two_without_launching_flutter(self):
        env_file = self.write_env("API_BASE_URL=http://host/\n")
        error_output = StringIO()
        with patch.object(run_dev.subprocess, "run") as flutter, redirect_stderr(error_output):
            result = run_dev.main(["--env-file", str(env_file)])
        self.assertEqual(result, 2)
        self.assertIn("API_BASE_URL", error_output.getvalue())
        flutter.assert_not_called()

    def test_missing_flutter_returns_127(self):
        env_file = self.write_env(f"API_BASE_URL={VALID_URL}\n")
        error_output = StringIO()
        with patch.object(
            run_dev.subprocess, "run", side_effect=FileNotFoundError
        ), redirect_stderr(error_output):
            result = run_dev.main(["--env-file", str(env_file)])
        self.assertEqual(result, 127)
        self.assertIn("Flutter was not found", error_output.getvalue())


class FlutterCommandTests(unittest.TestCase):
    def test_command_contains_only_explicit_development_configuration(self):
        command = build_flutter_command(VALID_URL, ["--profile", "-d", "device-id"])
        self.assertEqual(
            command,
            [
                "flutter",
                "run",
                "--dart-define=APP_ENV=development",
                f"--dart-define=API_BASE_URL={VALID_URL}",
                "--profile",
                "-d",
                "device-id",
            ],
        )

    def test_config_file_and_release_overrides_are_rejected(self):
        unsafe_arguments = [
            ["--dart-define-from-file=secrets.json"],
            ["--dart-define-from-file", "secrets.json"],
            ["--dart-define=API_BASE_URL=https://other.example/api/v1"],
            ["--dart-define", "APP_ENV=production"],
            ["--release"],
        ]
        for arguments in unsafe_arguments:
            with self.subTest(arguments=arguments), self.assertRaises(DevConfigError):
                build_flutter_command(VALID_URL, arguments)


if __name__ == "__main__":
    unittest.main()
