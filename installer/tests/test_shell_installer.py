"""Isolated process-level tests: python3 -m unittest discover -s installer/tests -p 'test_*.py'."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / 'installer/install-translators-and-style.sh'
BUNDLED_ID = '70dc2609-d6fd-415a-822c-a2c04293cb5a'
MOCK = '''#!/usr/bin/env python3
import json, os, pathlib, shutil, sys
state_path = pathlib.Path(os.environ['SVELIC_TEST_STATE'])
state = json.loads(state_path.read_text())
if pathlib.Path(sys.argv[0]).name == 'pgrep':
    outcomes = json.loads(os.environ.get('SVELIC_TEST_PROCESSES', '[1]'))
    n = state.get('checks', 0)
    state['checks'] = n + 1
    state_path.write_text(json.dumps(state))
    sys.exit(outcomes[min(n, len(outcomes) - 1)])
url = sys.argv[-1]
output = pathlib.Path(sys.argv[sys.argv.index('--output') + 1])
state.setdefault('downloads', []).append(url)
state_path.write_text(json.dumps(state))
if '/commits/' in url:
    output.write_text(json.dumps({'sha': 'a' * 40}, indent=2 if os.environ.get('SVELIC_TEST_PRETTY_JSON') else None))
else:
    if url.endswith(os.environ.get('SVELIC_TEST_FAIL_FILE', 'never-match')):
        print('Simulated HTTP download failure', file=sys.stderr)
        sys.exit(22)
    if url.endswith('install-translators-and-style.sh'):
        relative = 'installer/install-translators-and-style.sh'
    else:
        relative = url.split('/' + 'a' * 40 + '/', 1)[1]
    shutil.copyfile(pathlib.Path(os.environ['SVELIC_TEST_SOURCE']) / relative, output)
    if url.endswith(os.environ.get('SVELIC_TEST_INVALID', 'never-match')):
        output.write_text('<html>Unexpected download</html>')
'''


class ShellInstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='svelic-shell-test-')
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.library = self.directory / 'Library with spaces å'
        self.library.mkdir()
        (self.library / 'zotero.sqlite').write_bytes(b'library sentinel')
        self.bin = self.directory / 'bin'
        self.bin.mkdir()
        for tool in ('curl', 'pgrep'):
            path = self.bin / tool
            path.write_text(MOCK)
            path.chmod(0o755)
        self.state = self.directory / 'state.json'
        self.state.write_text('{}')
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        SVELIC_TEST_SOURCE=str(ROOT), SVELIC_TEST_STATE=str(self.state))

    def run_installer(self, *args, answers='', processes=None, success=True, script=SCRIPT):
        if processes is not None:
            self.env['SVELIC_TEST_PROCESSES'] = json.dumps(processes)
        result = subprocess.run(['bash', str(script), '--data-directory', str(self.library), *args],
                                input=answers, text=True, capture_output=True, env=self.env, timeout=20)
        if success:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def bundled(self, name='UpToDate References.js'):
        path = self.library / 'translators' / name
        path.parent.mkdir(exist_ok=True)
        path.write_text(json.dumps({'translatorID': BUNDLED_ID, 'label': 'UpToDate References'}, indent=2))
        return path

    def test_install_default_yes_and_repeat_skip(self):
        bundled = self.bundled()
        self.run_installer(answers='\n')
        self.assertFalse(bundled.exists())
        self.assertTrue(Path(str(bundled) + '.disabled').exists())
        expected = list((ROOT / 'translators').glob('*.js')) + list((ROOT / 'styles').glob('*.csl'))
        before = {}
        for source in expected:
            target = self.library / source.relative_to(ROOT)
            self.assertEqual(target.read_bytes(), source.read_bytes())
            before[target] = target.stat().st_mtime_ns
        result = self.run_installer('--disable-default-uptodate', 'yes')
        self.assertEqual(result.stdout.count('Unchanged:'), len(expected))
        self.assertEqual(before, {p: p.stat().st_mtime_ns for p in before})
        self.assertFalse((self.library / 'svelic-installer-backups').exists())
        self.assertEqual((self.library / 'zotero.sqlite').read_bytes(), b'library sentinel')

    def test_opt_out_and_disable_by_id_only(self):
        bundled = self.bundled('Renamed bundled translator.js')
        other = self.library / 'translators/UpToDate.js'
        other.write_text(json.dumps({'translatorID': 'different-id', 'label': 'UpToDate References'}, indent=2))
        self.run_installer(answers='n\n')
        self.assertTrue(bundled.exists())
        self.run_installer('--disable-default-uptodate', 'yes')
        self.assertFalse(bundled.exists())
        self.assertTrue(other.exists())
        custom = self.library / 'translators/UpToDate_article.js'
        self.assertEqual(custom.read_bytes(), (ROOT / 'translators/UpToDate_article.js').read_bytes())
        self.bundled(bundled.name)
        self.run_installer('--disable-default-uptodate', 'yes')
        self.assertEqual(len(list(bundled.parent.glob(bundled.name + '.disabled*'))), 2)

    def test_style_and_translator_updates_back_up_originals(self):
        self.run_installer('--disable-default-uptodate', 'no')
        paths = ['translators/FASS.js', 'styles/nlm-citation-sequence-unnumbered-bibliography.csl']
        for relative in paths:
            (self.library / relative).write_text('old local contents')
        self.run_installer('--disable-default-uptodate', 'no')
        backup_runs = list((self.library / 'svelic-installer-backups').iterdir())
        self.assertEqual(len(backup_runs), 1)
        for relative in paths:
            self.assertEqual((backup_runs[0] / relative).read_text(), 'old local contents')
            self.assertEqual((self.library / relative).read_bytes(), (ROOT / relative).read_bytes())
        self.assertFalse(list(self.library.rglob('*.XXXXXX')))

    def test_last_download_failure_or_invalid_content_changes_nothing(self):
        bundled = self.bundled()
        style = 'nlm-citation-sequence-unnumbered-bibliography.csl'
        for option, suffix in [('SVELIC_TEST_FAIL_FILE', style), ('SVELIC_TEST_INVALID', style),
                               ('SVELIC_TEST_INVALID', 'UpToDate_article.js')]:
            with self.subTest(option=option, suffix=suffix):
                self.env[option] = suffix
                self.run_installer('--disable-default-uptodate', 'yes', success=False)
                self.assertTrue(bundled.exists())
                self.assertEqual(len(list((self.library / 'translators').iterdir())), 1)
                self.assertFalse((self.library / 'styles').exists())
                del self.env[option]

    def test_running_zotero_retry_and_cancel(self):
        result = self.run_installer(answers='q\n', processes=[0])
        self.assertIn('Zotero is still running', result.stdout)
        self.assertIn('Installation cancelled', result.stdout)
        self.assertNotIn('downloads', json.loads(self.state.read_text()))
        self.state.write_text('{}')
        result = self.run_installer(answers='\n\n', processes=[0, 1, 1])
        self.assertIn('press Enter to retry', result.stdout)
        self.assertTrue((self.library / 'translators/UpToDate_article.js').exists())

    def test_zotero_opened_during_download(self):
        result = self.run_installer('--disable-default-uptodate', 'no', answers='q\n', processes=[1, 0])
        self.assertIn('Installation cancelled', result.stdout)
        self.assertFalse((self.library / 'translators').exists())

    def test_pretty_github_api_response(self):
        self.env['SVELIC_TEST_PRETTY_JSON'] = '1'
        self.run_installer('--disable-default-uptodate', 'no')

    def test_process_check_failure_is_reported(self):
        result = self.run_installer(processes=[2], success=False)
        self.assertIn('Could not check whether Zotero is running', result.stderr)

    def test_custom_directory_prompt_and_invalid_options(self):
        missing = self.directory / 'Missing library'
        result = self.run_installer('--data-directory', str(missing), answers=str(self.library) + '\n\n')
        self.assertIn('No Zotero library found', result.stdout)
        self.run_installer('--disable-default-uptodate', 'maybe', success=False)
        self.run_installer('--ref', 'bad ref', success=False)

    def test_macos_launcher_with_local_and_downloaded_shell_script(self):
        launcher = self.directory / 'install-translators-and-style.command'
        shutil.copyfile(ROOT / 'installer/install-translators-and-style.command', launcher)
        self.run_installer('--disable-default-uptodate', 'no', script=launcher)
        self.assertTrue(any(url.endswith('install-translators-and-style.sh')
                            for url in json.loads(self.state.read_text())['downloads']))
        shutil.copyfile(SCRIPT, self.directory / SCRIPT.name)
        self.state.write_text('{}')
        self.run_installer('--disable-default-uptodate', 'no', script=launcher)
        self.assertFalse(any(url.endswith('install-translators-and-style.sh')
                             for url in json.loads(self.state.read_text())['downloads']))


if __name__ == '__main__':
    unittest.main()
