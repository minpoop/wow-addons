"""The synthetic interface used here exists only inside a temporary directory."""
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[1]


class PackagingTests(unittest.TestCase):
    def test_packaging_is_explicit_and_does_not_modify_sources(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            shutil.copytree(ROOT / 'ForeverXP', root / 'ForeverXP')
            (root / 'tools').mkdir()
            shutil.copy(ROOT / 'tools/package.py', root / 'tools/package.py')
            command = [sys.executable, str(root / 'tools/package.py')]
            subprocess.run(command, check=True, capture_output=True)
            with zipfile.ZipFile(root / 'dist/ForeverXP-dev.zip') as archive:
                self.assertIn('## Interface: 16001\n', archive.read('ForeverXP/ForeverXP.toc').decode())
            invalid = subprocess.run(command + ['--interface', '0'], capture_output=True)
            self.assertNotEqual(invalid.returncode, 0)
            manifest = root / 'ForeverXP/ForeverXP.toc'
            original = manifest.read_bytes()
            subprocess.run(command + ['--interface', '999999'], check=True, capture_output=True)
            self.assertEqual(manifest.read_bytes(), original)
            with zipfile.ZipFile(root / 'dist/ForeverXP-dev.zip') as archive:
                self.assertIn('## Interface: 999999\n', archive.read('ForeverXP/ForeverXP.toc').decode())
                self.assertIn('ForeverXP/Core/Bootstrap.lua', archive.namelist())
                for module in ('Questing/LevelingCampaign.lua', 'Data/QuestGuides/Alliance/Levels1_20.lua', 'Data/QuestGuides/Alliance/Levels1_60.lua'):
                    self.assertIn('ForeverXP/' + module, archive.namelist())
                    self.assertIn(module, archive.read('ForeverXP/ForeverXP.toc').decode())
                self.assertNotIn('ForeverXP/Assets/JamesSunderland.tga', archive.namelist())
                self.assertFalse(any('Tests/' in name for name in archive.namelist()))
                self.assertTrue(all(name.startswith('ForeverXP/') for name in archive.namelist()))


if __name__ == '__main__':
    unittest.main()
