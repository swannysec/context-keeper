"""Focused resolver and hook tests; all state is in disposable fixtures."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[2]


class Roots(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.project = self.base / 'project with spaces'
        self.home = self.base / 'home'
        self.tmp = self.base / 'tmp'
        for path in (self.project, self.home, self.tmp):
            path.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.tmp))

    def run_script(self, script, *args, payload=''):
        return subprocess.run(['/bin/bash', str(REPO / script), *args],
                              cwd=self.project, env=self.env, input=payload,
                              text=True, capture_output=True, timeout=20)

    def write(self, path, text):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def test_resolution_matrix_independent_scopes(self):
        for scope in (self.project, self.home):
            for new, legacy in ((False, False), (True, False), (False, True), (True, True)):
                with self.subTest(scope=scope.name, new=new, legacy=legacy):
                    for name in ('.ai', '.claude'):
                        shutil.rmtree(scope / name, ignore_errors=True)
                    if new:
                        (scope / '.ai/memory').mkdir(parents=True)
                    if legacy:
                        (scope / '.claude/memory').mkdir(parents=True)
                    before = sorted(str(p) for p in scope.rglob('*'))
                    args = ('--global',) if scope == self.home else ()
                    result = self.run_script('tools/memory-root.sh', *args)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    expected = scope / ('.claude/memory' if legacy and not new else '.ai/memory')
                    self.assertEqual(result.stdout.strip(), str(expected))
                    self.assertEqual('both' in result.stderr.lower(), new and legacy)
                    self.assertEqual(sorted(str(p) for p in scope.rglob('*')), before)

    def test_new_root_hook_read_write_search_handoff(self):
        memory = self.project / '.ai/memory'
        self.write(memory / 'active-context.md', '# Active Context\n## Current Focus\nROOTCHECK\n')
        self.write(memory / '.memory-config.md', '---\ncontext_window_tokens: 100000\nauto_clear: true\nauto_clear_pct: 90\n---\n')
        self.write(self.home / '.claude/projects/native/memory/MEMORY.md', 'NATIVE\n')
        result = self.run_script('hooks/session-start.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('.ai/memory', json.loads(result.stdout)['hookSpecificOutput']['additionalContext'])
        self.assertTrue((memory / '.last-sync').is_file())
        transcript = self.base / 'transcript.jsonl'
        self.write(transcript, json.dumps({'type': 'assistant', 'message': {'usage': {'input_tokens': 92000}}}) + '\n')
        payload = json.dumps({'cwd': str(self.project), 'session_id': 'roots',
                              'transcript_path': str(transcript), 'user_message': 'Actually, use ROOTCHECK',
                              'tool_name': 'Read', 'tool_input': {'file_path': 'README.md'}})
        result = self.run_script('hooks/post-tool-use.sh', payload=payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('`Read`', next((memory / 'sessions').glob('*-observations.md')).read_text())
        self.write(self.tmp / 'conkeeper/synced-roots', str(int(time.time())))
        result = self.run_script('hooks/user-prompt-submit.sh', payload=payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((memory / 'corrections-queue.md').is_file())
        self.assertTrue((memory / '.handoffs/.pending-handoff-roots.md').is_file())
        self.assertIn('ROOTCHECK', self.run_script('tools/memory-search.sh', 'ROOTCHECK').stdout)
        result = self.run_script('hooks/session-start.sh')
        self.assertIn('conkeeper-handoff', result.stdout)
        self.assertTrue((memory / '.handoffs/.last-handoff-roots.md').is_file())
        self.assertEqual((self.home / '.claude/projects/native/memory/MEMORY.md').read_text(), 'NATIVE\n')
        self.assertFalse((self.project / '.claude').exists())

    def test_write_parent_symlink_refused(self):
        memory = self.project / '.ai/memory'
        memory.mkdir(parents=True)
        outside = self.base / 'outside'
        outside.mkdir()
        (memory / 'sessions').symlink_to(outside, target_is_directory=True)
        result = self.run_script('hooks/session-start.sh')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('memory-system-active', result.stdout)
        self.assertEqual(list(outside.iterdir()), [])

    def test_unsafe_selected_root_never_falls_back(self):
        legacy = self.project / '.claude/memory'
        legacy.mkdir(parents=True)
        (self.project / '.ai').mkdir()
        selected = self.project / '.ai/memory'
        native = self.project / '.claude/skills'
        native.mkdir()
        selected.symlink_to(native, target_is_directory=True)
        result = self.run_script('tools/memory-root.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertIn('agent-native', result.stderr)
        self.assertEqual(list(native.iterdir()), [])
        selected.unlink()
        selected.write_text('not a directory\n')
        result = self.run_script('tools/memory-root.sh')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Invalid', result.stderr)
        self.assertEqual(list(legacy.iterdir()), [])

    def test_unwritable_root_does_not_write_legacy(self):
        memory = self.project / '.ai/memory'
        memory.mkdir(parents=True)
        legacy = self.project / '.claude/memory'
        legacy.mkdir(parents=True)
        memory.chmod(0o500)
        try:
            if os.access(memory, os.W_OK):
                self.skipTest('Current user can write despite mode 500')
            result = self.run_script('hooks/session-start.sh')
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('Permission denied', result.stderr)
            self.assertEqual(list(memory.iterdir()), [])
            self.assertEqual(list(legacy.iterdir()), [])
        finally:
            memory.chmod(0o700)


if __name__ == '__main__':
    unittest.main(verbosity=2)
