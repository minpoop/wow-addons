import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ContentTests(unittest.TestCase):
    def test_schema_and_missing_quest_detection(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            guide = root / 'guide.json'
            known = root / 'known.json'
            guide.write_text(json.dumps({'id': 'fixture', 'title': 'Synthetic', 'steps': [
                {'id': 'one', 'type': 'ACCEPT_QUEST', 'text': 'Fixture', 'questId': 990001}]}))
            command = [sys.executable, str(ROOT / 'tools/validate_content.py'), 'guide', str(guide)]
            result = subprocess.run(command, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertNotEqual(subprocess.run(command + ['--production'], capture_output=True).returncode, 0)
            known.write_text('[]')
            missing = subprocess.run(command + ['--known-quests', str(known)], capture_output=True, text=True)
            self.assertNotEqual(missing.returncode, 0)
            self.assertIn('990001', missing.stderr)
            known.write_text('[990001]')
            self.assertEqual(subprocess.run(command + ['--known-quests', str(known)], capture_output=True).returncode, 0)

    def test_duplicate_keys_nonfinite_and_executable_inputs_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            content = Path(directory) / 'content.json'
            command = [sys.executable, str(ROOT / 'tools/validate_content.py'), 'route', str(content)]
            for data in ['{"id":"a","id":"b"}', '{"x":NaN}', 'os.execute("unsafe")', 'null']:
                content.write_text(data)
                self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)


if __name__ == '__main__':
    unittest.main()
