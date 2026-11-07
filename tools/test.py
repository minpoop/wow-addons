"""Run actual Lua 5.1; no WoW client or game assets required."""
from pathlib import Path
import os
import subprocess
import sys
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
os.chdir(root)
lua = LuaRuntime(unpack_returned_tuples=True)
assert lua.eval('_VERSION') == 'Lua 5.1'
lua.execute((root / 'Tests/run.lua').read_text())
subprocess.run([sys.executable, '-m', 'unittest', 'discover', '-s', 'Tests', '-p', 'test_*.py'], check=True)
