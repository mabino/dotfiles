#!/usr/bin/env python3
"""Tests for the brewfile-reconcile script (~/.local/bin/brewfile-reconcile).

Run with: python3 -m unittest discover ~/.config/yadm/tests
"""

import importlib.util
import os
import subprocess
import sys
import tempfile
import unittest

SCRIPT = os.path.expanduser("~/.local/bin/brewfile-reconcile")

spec = importlib.util.spec_from_loader("brewfile_reconcile", loader=None)
mod = importlib.util.module_from_spec(spec)
with open(SCRIPT, encoding="utf-8") as f:
    exec(compile(f.read(), SCRIPT, "exec"), mod.__dict__)


def write(path, content):
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


LOCAL = """\
# Terminal multiplexer
brew "tmux"
# GitHub command-line tool
brew "gh"
# Terminal-based AI coding assistant
cask "claude-code"
cargo "goboscript"
"""

REMOTE = """\
# GitHub command-line tool
brew "gh"
# Tool to unpack installers created by Inno Setup
brew "innoextract"
# Google Chromium, sans integration with Google
cask "ungoogled-chromium"
"""


class ReconcileTests(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.local = os.path.join(self.dir.name, "local")
        self.remote = os.path.join(self.dir.name, "remote")
        write(self.local, LOCAL)
        write(self.remote, REMOTE)

    def tearDown(self):
        self.dir.cleanup()

    def merged(self, removals=()):
        return mod.render(
            mod.union(mod.parse(self.local), mod.parse(self.remote), removals)
        )

    def test_union_keeps_entries_from_both_sides(self):
        out = self.merged()
        for name in ("tmux", "gh", "innoextract", "claude-code",
                     "ungoogled-chromium", "goboscript"):
            self.assertIn(f'"{name}"', out)

    def test_union_deduplicates_shared_entries(self):
        self.assertEqual(self.merged().count('brew "gh"'), 1)

    def test_comments_stay_attached(self):
        out = self.merged().splitlines()
        idx = out.index('brew "innoextract"')
        self.assertEqual(out[idx - 1], "# Tool to unpack installers created by Inno Setup")

    def test_secondary_entries_append_to_their_directive_group(self):
        out = self.merged().splitlines()
        self.assertLess(out.index('brew "innoextract"'),
                        out.index('cask "claude-code"'))

    def test_remove_drops_entry_from_both_sides(self):
        out = self.merged(removals=["gh"])
        self.assertNotIn('brew "gh"', out)
        self.assertNotIn("# GitHub command-line tool", out)

    def test_remove_matches_tap_short_name(self):
        write(self.local, 'tap "user/repo"\nbrew "tmux"\n')
        write(self.remote, "")
        out = self.merged(removals=["repo"])
        self.assertNotIn("user/repo", out)
        self.assertIn('brew "tmux"', out)

    def test_options_preserved_and_primary_wins(self):
        write(self.local, 'brew "colima", restart_service: :changed\n')
        write(self.remote, 'brew "colima"\n')
        out = self.merged()
        self.assertEqual(out, 'brew "colima", restart_service: :changed\n')

    def test_git_merge_mode_writes_union_to_ours(self):
        ancestor = os.path.join(self.dir.name, "ancestor")
        write(ancestor, "")
        subprocess.run(
            [sys.executable, SCRIPT, "git-merge", ancestor, self.remote, self.local],
            check=True,
        )
        with open(self.remote, encoding="utf-8") as f:
            out = f.read()
        for name in ("tmux", "innoextract", "goboscript"):
            self.assertIn(f'"{name}"', out)

    def test_union_cli_with_output_flag(self):
        out_path = os.path.join(self.dir.name, "out")
        subprocess.run(
            [sys.executable, SCRIPT, "union", self.local, self.remote,
             "--remove", "tmux", "-o", out_path],
            check=True,
        )
        with open(out_path, encoding="utf-8") as f:
            out = f.read()
        self.assertNotIn('brew "tmux"', out)
        self.assertIn('brew "innoextract"', out)


if __name__ == "__main__":
    unittest.main()
