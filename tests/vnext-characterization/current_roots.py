"""Regression coverage seeded by Phase 1; root expectations updated for Phase 2.

All hooks execute with Bash 3.2 on macOS. HOME and TMPDIR are replaced only
in child-process environments; fixtures never use developer/native memory.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[2]


def snapshot(root):
    return {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in root.rglob('*') if p.is_file() and not p.is_symlink()}


class CurrentRoots(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='conkeeper-characterization-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name).resolve()
        self.project = self.base / 'project with spaces'
        self.home = self.base / 'home with spaces'
        self.tmp = self.base / 'tmp'
        for path in (self.project, self.home, self.tmp):
            path.mkdir()
        self.env = dict(os.environ, HOME=str(self.home), TMPDIR=str(self.tmp))

    def write(self, path, content):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def memory(self, scope, root, marker):
        path = scope / root / 'memory'
        self.write(path / 'active-context.md', '# Active Context\n## Current Focus\n' + marker + '\n')
        return path

    def run_script(self, script, cwd=None, args=(), payload=None):
        result = subprocess.run(['/bin/bash', str(REPO / script), *args],
                                cwd=cwd or self.project, env=self.env,
                                input='' if payload is None else payload,
                                text=True, capture_output=True, timeout=30)
        return result

    def start(self, cwd=None):
        result = self.run_script('hooks/session-start.sh', cwd)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)['hookSpecificOutput']['additionalContext']

    def search(self, *args, cwd=None, status=0):
        result = self.run_script('tools/memory-search.sh', cwd, args)
        self.assertEqual(result.returncode, status, result.stderr)
        self.assertNotIn('failed at line', result.stderr)
        return result.stdout

    def test_project_and_global_roots_independently(self):
        # Fixed-root matrix: new first, legacy fallback, new target when absent.
        for scope_name in ('project', 'global'):
            for new, legacy in ((False, False), (True, False), (False, True), (True, True)):
                with self.subTest(scope=scope_name, new=new, legacy=legacy):
                    scope = self.project if scope_name == 'project' else self.home
                    for fixture_scope in (self.project, self.home):
                        for root in ('.ai', '.claude'):
                            shutil.rmtree(fixture_scope / root, ignore_errors=True)
                    if new:
                        self.memory(scope, '.ai', 'NEWROOTMARKER')
                    if legacy:
                        self.memory(scope, '.claude', 'LEGACYROOTMARKER')
                    before = snapshot(scope / '.claude') if legacy else {}
                    context = self.start()
                    selected = scope / ('.ai/memory' if new or not legacy else '.claude/memory')
                    expected = ('Project memory: ' if scope_name == 'project' else 'Global memory: ') + str(selected)
                    self.assertEqual(expected in context, new or legacy)
                    output = self.search('ROOTMARKER', *(['--global'] if scope_name == 'global' else []))
                    self.assertEqual('LEGACYROOTMARKER' in output, legacy and not new)
                    self.assertEqual('NEWROOTMARKER' in output, new)
                    if legacy and new or scope_name == 'global':
                        self.assertEqual(snapshot(scope / '.claude') if legacy else {}, before)
                    self.assertEqual((scope / '.ai').exists(), new)
                    self.assertEqual((scope / '.claude').exists(), legacy)
                    if scope_name == 'project' and (new or legacy):
                        self.assertTrue((selected / '.last-sync').is_file())
                        self.assertTrue(list((selected / 'sessions').glob('*-observations.md')))

    def test_mixed_scopes(self):
        self.memory(self.project, '.ai', 'PROJECTNEWROOTMARKER')
        self.memory(self.home, '.claude', 'GLOBALLEGACYROOTMARKER')
        context = self.start()
        self.assertIn('Project memory: ' + str(self.project / '.ai/memory'), context)
        self.assertIn('Global memory: ' + str(self.home / '.claude/memory'), context)
        self.assertIn('GLOBALLEGACYROOTMARKER', self.search('ROOTMARKER', '--global'))
        self.assertFalse((self.project / '.claude').exists())

    def test_search_read_only_and_cwd_assumption(self):
        memory = self.memory(self.project, '.claude', 'LEGACYROOTMARKER')
        before = snapshot(self.project)
        self.assertIn('LEGACYROOTMARKER', self.search('ROOTMARKER'))
        self.assertEqual(snapshot(self.project), before)
        child = self.project / 'src'
        child.mkdir()
        self.assertNotIn('LEGACYROOTMARKER', self.search('ROOTMARKER', cwd=child))
        self.assertIn('memory-system-available', self.start(child))
        self.assertFalse((child / '.claude').exists())
        self.assertFalse((memory / '.last-sync').exists())

    def test_config_bootstrap_and_symlink_refusal(self):
        memory = self.memory(self.project, '.ai', 'LEGACYROOTMARKER')
        self.write(memory / 'friction.md', 'FRICTIONMARKER\n')
        self.write(self.project / '.claude/memory/.memory-config.md', '---\ntoken_budget: economy\n---\n')
        self.assertIn('FRICTIONMARKER', self.start())
        config = self.write(memory / '.memory-config.md', '---\ntoken_budget: economy # inline comment\n---\n')
        self.assertNotIn('FRICTIONMARKER', self.start())
        config.unlink()
        outside = self.write(self.base / 'outside-config.md', '---\ntoken_budget: economy\n---\n')
        config.symlink_to(outside)
        self.assertIn('FRICTIONMARKER', self.start())
        self.assertEqual(outside.read_text(), '---\ntoken_budget: economy\n---\n')

    def test_json_cwd_writers_and_native_state(self):
        memory = self.memory(self.project, '.claude', 'LEGACYROOTMARKER')
        native_paths = (self.home / '.claude/projects/native/memory/MEMORY.md',
                        self.home / '.hermes/memories/MEMORY.md',
                        self.project / '.codex/native-session',
                        self.project / '.agents/skills/native/SKILL.md',
                        self.project / '.pi/native-session')
        for path in native_paths:
            self.write(path, 'NATIVE-SENTINEL\n')
        before = {str(p): p.read_bytes() for p in native_paths}
        self.start()
        transcript = self.write(self.base / 'transcript.jsonl', json.dumps({
            'type': 'assistant', 'message': {'usage': {'input_tokens': 1000}}}) + '\n')
        payload = json.dumps({'cwd': str(self.project), 'session_id': 'phase1',
                              'transcript_path': str(transcript),
                              'user_message': 'Actually, use the existing interface',
                              'tool_name': 'Read', 'tool_input': {'file_path': 'README.md'}})
        for hook in ('post-tool-use', 'user-prompt-submit', 'pre-compact', 'stop'):
            result = self.run_script('hooks/' + hook + '.sh', self.base, payload=payload)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotIn('failed at line', result.stderr)
        self.assertIn('`Read`', next((memory / 'sessions').glob('*-observations.md')).read_text())
        self.assertIn('Actually', (memory / 'corrections-queue.md').read_text())
        self.assertFalse((self.base / '.claude').exists())
        self.assertEqual({str(p): p.read_bytes() for p in native_paths}, before)

    def test_search_privacy_and_file_symlink(self):
        memory = self.memory(self.project, '.claude', 'PUBLICROOTMARKER')
        self.write(memory / 'blocks.md', 'PUBLICROOTMARKER\n<private>\nSECRETROOTMARKER\n</private>\n')
        self.write(memory / 'private.md', '---\nprivate: true\n---\nSECRETROOTMARKER\n')
        target = self.write(self.base / 'outside.md', 'ESCAPEROOTMARKER\n')
        (memory / 'linked.md').symlink_to(target)
        output = self.search('ROOTMARKER')
        self.assertIn('PUBLICROOTMARKER', output)
        self.assertNotIn('SECRETROOTMARKER', output)
        self.assertNotIn('ESCAPEROOTMARKER', output)

    def test_session_start_rejects_external_root_symlink(self):
        outside = self.memory(self.base / 'outside', '.claude', 'ESCAPEROOTMARKER')
        (self.project / '.claude').mkdir()
        (self.project / '.claude/memory').symlink_to(outside, target_is_directory=True)
        before = snapshot(outside)
        result = self.run_script('hooks/session-start.sh')
        self.assertEqual(result.returncode, 0)
        self.assertIn('escapes', result.stderr)
        self.assertEqual(snapshot(outside), before)

    def test_session_start_sessions_symlink_refusal(self):
        # SessionStart and PostToolUse both refuse a symlinked sessions parent.
        memory = self.memory(self.project, '.claude', 'LEGACYROOTMARKER')
        outside = self.base / 'outside-sessions'
        outside.mkdir()
        (memory / 'sessions').symlink_to(outside, target_is_directory=True)
        self.start()
        self.assertEqual(list(outside.iterdir()), [])
        before = snapshot(outside)
        payload = json.dumps({'cwd': str(self.project), 'session_id': 'phase1',
                              'tool_name': 'Read', 'tool_input': {'file_path': 'README.md'}})
        result = self.run_script('hooks/post-tool-use.sh', payload=payload)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(snapshot(outside), before)

    def test_cross_project_mixed_roots_depth_and_config(self):
        memory = self.memory(self.project, '.claude', 'CURRENTROOTMARKER')
        parent = self.base / 'other projects'
        self.memory(parent / 'legacy', '.claude', 'OTHERLEGACYROOTMARKER')
        self.memory(parent / 'new', '.ai', 'OTHERNEWROOTMARKER')
        self.memory(parent / 'both', '.claude', 'BOTHLEGACYROOTMARKER')
        self.memory(parent / 'both', '.ai', 'BOTHNEWROOTMARKER')
        self.memory(parent / 'nested/deep', '.claude', 'DEEPROOTMARKER')
        config = self.write(memory / '.memory-config.md', '---\nproject_search_paths: [' + json.dumps(str(parent)) + ', ' + json.dumps(str(parent)) + ']\n---\n')
        before = snapshot(parent)
        output = self.search('ROOTMARKER', '--cross-project')
        for marker in ('CURRENTROOTMARKER', 'OTHERLEGACYROOTMARKER', 'BOTHNEWROOTMARKER', 'OTHERNEWROOTMARKER'):
            self.assertEqual(output.count(marker), 1)
        for marker in ('BOTHLEGACYROOTMARKER', 'DEEPROOTMARKER'):
            self.assertNotIn(marker, output)
        self.assertEqual(snapshot(parent), before)
        config.write_text('---\nproject_search_paths: disabled\n---\n')
        self.search('ROOTMARKER', '--cross-project', status=1)

    def test_local_candidate_history_excluded_from_default_search(self):
        memory = self.memory(self.project, '.claude', 'ORDINARYKNOWLEDGEMARKER')
        parent = self.base / 'other projects'
        other = self.memory(parent / 'legacy', '.claude', 'OTHERORDINARYKNOWLEDGEMARKER')
        missing_store = self.base / 'unreachable knowledge store'
        for state in ('pending', 'deferred', 'rejected'):
            for root, scope in ((memory, 'LOCAL'), (other, 'OTHER')):
                self.write(root / 'sessions' / (state + '-handoff.md'),
                           '# Knowledge candidate\nReview state: ' + state +
                           '\n' + scope + state.upper() + 'CANDIDATEMARKER\n')
        for setting in ('', 'knowledge_workspace: ' + json.dumps(str(missing_store)) + '\n'):
            with self.subTest(workspace='unreachable' if setting else 'absent'):
                config = '---\nproject_search_paths: [' + json.dumps(str(parent)) + ']\n' + setting + '---\n'
                for root in (memory, other):
                    self.write(root / '.memory-config.md', config)
                before = snapshot(self.base)
                project_output = self.search('MARKER')
                cross_output = self.search('MARKER', '--cross-project')
                self.assertIn('ORDINARYKNOWLEDGEMARKER', project_output)
                self.assertIn('OTHERORDINARYKNOWLEDGEMARKER', cross_output)
                self.assertNotIn('CANDIDATEMARKER', project_output)
                self.assertNotIn('CANDIDATEMARKER', cross_output)
                project_history = self.search('CANDIDATEMARKER', '--sessions')
                cross_history = self.search('CANDIDATEMARKER', '--sessions', '--cross-project')
                for state in ('pending', 'deferred', 'rejected'):
                    self.assertIn('LOCAL' + state.upper() + 'CANDIDATEMARKER', project_history)
                    self.assertIn('OTHER' + state.upper() + 'CANDIDATEMARKER', cross_history)
                    self.assertIn('Review state: ' + state,
                                  self.search('Review state: ' + state, '--sessions', '--cross-project'))
                self.assertEqual(snapshot(self.base), before)
                self.assertFalse(missing_store.exists())

    def test_installer_instruction_preservation_and_repeat(self):
        agents = self.write(self.project / 'AGENTS.md', '# Existing instructions\nKEEP-AGENTS\n')
        claude = self.write(self.project / 'CLAUDE.md', '# Native fallback\nKEEP-CLAUDE\n')
        self.write(self.project / 'README.md', '# Fixture\n')
        result = self.run_script('tools/install.sh', payload='1\ny\ny\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(agents.read_text().startswith('# Existing instructions\nKEEP-AGENTS\n'))
        first = agents.read_bytes()
        result = self.run_script('tools/install.sh', payload='1\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(agents.read_bytes(), first)
        self.assertTrue(claude.read_text().startswith('# Native fallback\nKEEP-CLAUDE\n'))
        self.assertIn('ConKeeper Memory System', claude.read_text())
        self.assertFalse((self.project / '.claude').exists())

    def test_codex_installer_current_skill_selection(self):
        self.write(self.project / 'README.md', '# Fixture\n')
        target = self.project / '.agents/skills'
        sentinel = self.write(target / 'native/SKILL.md', 'KEEP-NATIVE\n')
        legacy = self.write(self.project / '.codex/skills/native/SKILL.md', 'KEEP-LEGACY-NATIVE\n')
        result = self.run_script('tools/install.sh', payload='3\n')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(sorted(p.name for p in target.iterdir()),
                         ['memory-config', 'memory-init', 'memory-search', 'memory-sync', 'native', 'session-handoff'])
        self.assertEqual(sentinel.read_text(), 'KEEP-NATIVE\n')
        self.assertEqual(legacy.read_text(), 'KEEP-LEGACY-NATIVE\n')
        for name in ('memory-init', 'memory-config', 'memory-search', 'memory-sync', 'session-handoff'):
            self.assertEqual((target / name / 'SKILL.md').read_bytes(),
                             (REPO / 'platforms/codex/.agents/skills' / name / 'SKILL.md').read_bytes())

    def test_installer_claude_only_project_creates_agents(self):
        self.write(self.project / 'README.md', '# Fixture\n')
        claude = self.write(self.project / 'CLAUDE.md', '# Legacy instructions\nKEEP-CLAUDE\n')
        result = self.run_script('tools/install.sh', payload='1\ny\ny\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('ConKeeper Memory System', (self.project / 'AGENTS.md').read_text())
        self.assertTrue(claude.read_text().startswith('# Legacy instructions\nKEEP-CLAUDE\n'))
        self.assertIn('ConKeeper Memory System', claude.read_text())
        self.assertFalse((self.project / '.claude').exists())

    def test_build_package_inventory_and_search_dependencies(self):
        source = self.base / 'build-source'
        source.mkdir()
        for directory in ('tools', 'platforms', 'core', 'skills', 'commands', 'hooks'):
            shutil.copytree(REPO / directory, source / directory)
        for filename in ('plugin.json', 'README.md', 'LICENSE'):
            shutil.copy2(REPO / filename, source / filename)
        result = subprocess.run(['/bin/bash', str(source / 'tools/build.sh')],
                                cwd=self.project, env=self.env,
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        dist = source / 'dist'
        self.assertEqual(sorted(p.name for p in dist.iterdir()),
                         ['claude-code', 'codex', 'copilot', 'cursor',
                          'universal', 'windsurf', 'zed'])
        self.memory(self.project, '.ai', 'PACKAGEDROOTMARKER')
        for package, directory, count in (
                ('claude-code', 'skills', 7), ('codex', '.agents/skills', 5),
                ('copilot', '.github/skills', 5), ('cursor', '.cursor/skills', 5)):
            self.assertEqual(len(list((dist / package / directory).rglob('SKILL.md'))), count)
            self.assertIn('tools/memory-search.sh',
                          (dist / package / directory / 'memory-search/SKILL.md').read_text())
            # Packages must include the referenced executable and its libraries.
            self.assertTrue((dist / package / 'tools/memory-search.sh').exists())
            result = subprocess.run(['/bin/bash', str(dist / package / 'tools/memory-search.sh'), 'PACKAGEDROOTMARKER'],
                                    cwd=self.project, env=self.env, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn('PACKAGEDROOTMARKER', result.stdout)
        self.assertTrue((dist / 'universal/core/workflows/memory-init.md').is_file())
        self.assertEqual(len(list((dist / 'codex/.codex/skills').rglob('SKILL.md'))), 5)
        for package in dist.iterdir():
            self.assertTrue((package / 'core/workflows/durable-knowledge.md').is_file())
            self.assertTrue((package / 'core/memory/templates/knowledge-proposal.md').is_file())
        self.write(self.project / 'README.md', '# Test project\n')
        result = subprocess.run(['/bin/bash', str(dist / 'universal/tools/install.sh')],
                                cwd=self.project, env=self.env, input='6\ny\ny\n',
                                capture_output=True, text=True, timeout=10)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        for directory in ('.github/skills', '.agents/skills', '.cursor/skills'):
            self.assertEqual(len(list((self.project / directory).rglob('SKILL.md'))), 5)
        self.assertTrue((self.project / '.windsurfrules').is_file())
        for filename in ('AGENTS.md', 'CLAUDE.md'):
            self.assertIn('ConKeeper Memory System', (self.project / filename).read_text())


if __name__ == '__main__':
    unittest.main(verbosity=2)
