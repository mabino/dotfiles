#!/usr/bin/env python3
"""Tests for bootstrap-local-agent and omlx-server scripts.

Run with: python3 -m unittest discover ~/.config/yadm/tests
"""

import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

def get_script_path(name):
    repo_path = Path(__file__).resolve().parents[3] / ".local" / "bin" / name
    if repo_path.exists():
        return repo_path
    home_path = Path(os.path.expanduser(f"~/.local/bin/{name}"))
    if home_path.exists():
        return home_path
    return repo_path

BOOTSTRAP_SCRIPT = get_script_path("bootstrap-local-agent")
OMLX_SCRIPT = get_script_path("omlx-server")


class BootstrapLocalAgentTests(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.TemporaryDirectory()
        self.workspace_dir = os.path.join(self.temp_dir.name, "local-coding-agent")
        self.models_dir = os.path.join(self.temp_dir.name, "models")
        self.omlx_home = os.path.join(self.temp_dir.name, "omlx_home")

    def tearDown(self):
        self.temp_dir.cleanup()

    def test_scripts_are_executable(self):
        self.assertTrue(os.access(BOOTSTRAP_SCRIPT, os.X_OK))
        self.assertTrue(os.access(OMLX_SCRIPT, os.X_OK))

    def test_help_flag(self):
        res = subprocess.run(
            [str(BOOTSTRAP_SCRIPT), "--help"],
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertIn("Usage: bootstrap-local-agent", res.stdout)
        self.assertIn("--silent", res.stdout)
        self.assertIn("--force", res.stdout)

    def test_omlx_server_help(self):
        res = subprocess.run(
            [str(OMLX_SCRIPT), "--help"],
            capture_output=True,
            text=True,
            check=True,
        )
        self.assertIn("Usage: omlx-server", res.stdout)
        self.assertIn("start", res.stdout)
        self.assertIn("status", res.stdout)

    def test_omlx_server_status_when_stopped(self):
        env = dict(os.environ, OMLX_HOME=self.omlx_home, OMLX_PORT="59999")
        res = subprocess.run(
            [str(OMLX_SCRIPT), "status"],
            capture_output=True,
            text=True,
            env=env,
            check=True,
        )
        self.assertIn("STOPPED", res.stdout)

    def test_scaffolding_creates_mise_toml(self):
        env = dict(
            os.environ,
            LOCAL_AGENT_DIR=self.workspace_dir,
            OMLX_MODELS_DIR=self.models_dir,
        )
        res = subprocess.run(
            [str(BOOTSTRAP_SCRIPT), "--force", "--silent", "--skip-models"],
            capture_output=True,
            text=True,
            env=env,
            check=True,
        )
        self.assertEqual(res.returncode, 0)
        mise_toml = os.path.join(self.workspace_dir, "mise.toml")
        self.assertTrue(os.path.isfile(mise_toml))

        with open(mise_toml, "r", encoding="utf-8") as f:
            content = f.read()

        self.assertIn('node = "22"', content)
        self.assertIn('python = "3.12"', content)
        self.assertIn('OPENAI_API_BASE = "http://127.0.0.1:8000/v1"', content)
        self.assertIn('OPENAI_API_KEY = "omlx-local"', content)
        self.assertIn('OPENAI_MODEL = "Qwen3.8-27B-4bit"', content)

        if sys.platform == "darwin":
            st = os.stat(self.workspace_dir)
            UF_HIDDEN = 0x8000
            self.assertTrue(bool(st.st_flags & UF_HIDDEN))

    def test_non_darwin_skip(self):
        mock_bin = os.path.join(self.temp_dir.name, "mock_bin_linux")
        os.makedirs(mock_bin, exist_ok=True)
        uname_mock = os.path.join(mock_bin, "uname")
        with open(uname_mock, "w", encoding="utf-8") as f:
            f.write('#!/bin/sh\nif [ "$1" = "-m" ]; then echo "x86_64"; else echo "Linux"; fi\n')
        os.chmod(uname_mock, stat.S_IRWXU)

        env = dict(
            os.environ,
            PATH=f"{mock_bin}:{os.environ.get('PATH', '')}",
            LOCAL_AGENT_DIR=self.workspace_dir,
        )
        res = subprocess.run(
            [str(BOOTSTRAP_SCRIPT), "--silent"],
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("host is not Apple Silicon macOS", res.stdout)
        self.assertFalse(os.path.exists(os.path.join(self.workspace_dir, "mise.toml")))

    def test_low_memory_skip(self):
        mock_bin = os.path.join(self.temp_dir.name, "mock_bin_darwin_low_mem")
        os.makedirs(mock_bin, exist_ok=True)
        uname_mock = os.path.join(mock_bin, "uname")
        with open(uname_mock, "w", encoding="utf-8") as f:
            f.write('#!/bin/sh\nif [ "$1" = "-m" ]; then echo "arm64"; else echo "Darwin"; fi\n')
        os.chmod(uname_mock, stat.S_IRWXU)

        sysctl_mock = os.path.join(mock_bin, "sysctl")
        with open(sysctl_mock, "w", encoding="utf-8") as f:
            f.write("#!/bin/sh\necho 17179869184\n")  # 16 GB
        os.chmod(sysctl_mock, stat.S_IRWXU)

        env = dict(
            os.environ,
            PATH=f"{mock_bin}:{os.environ.get('PATH', '')}",
            LOCAL_AGENT_DIR=self.workspace_dir,
        )
        res = subprocess.run(
            [str(BOOTSTRAP_SCRIPT), "--silent"],
            capture_output=True,
            text=True,
            env=env,
        )
        self.assertEqual(res.returncode, 0)
        self.assertIn("below 128GB threshold", res.stdout)
        self.assertFalse(os.path.exists(os.path.join(self.workspace_dir, "mise.toml")))

    def test_patch_mlx_server_aliases_logic(self):
        sample_code = """
        self._model_map = {}
        self._adapter_map = {}
        self._draft_model_map = {}
        self._model_map["default_model"] = self.cli_args.model
        self._adapter_map["default_model"] = self.cli_args.adapter_path
"""
        target = 'self._model_map["default_model"] = self.cli_args.model'
        patch = '''self._model_map["default_model"] = self.cli_args.model
        if self.cli_args.model:
            model_p = Path(self.cli_args.model)
            self._model_map[str(model_p)] = self.cli_args.model
            self._model_map[str(model_p.resolve())] = self.cli_args.model
            self._model_map[model_p.name] = self.cli_args.model
            self._model_map[f"mlx-community/{model_p.name}"] = self.cli_args.model'''
        patched = sample_code.replace(target, patch)
        self.assertIn("mlx-community/", patched)
        self.assertIn("default_model", patched)


if __name__ == "__main__":
    unittest.main()
