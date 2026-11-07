"""Package with an explicitly supplied, observed interface; never guess it."""
import argparse
from pathlib import Path
import re
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--interface', type=int,
                    help='Interface number observed on the target client; not its version/build')
parser.add_argument('--output', type=Path, help='ZIP path relative to repository root (default: dist/ForeverXP-dev.zip)')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
manifest = (root / 'ForeverXP/ForeverXP.toc').read_text()
observed = re.search(r'^## Interface: (\d+)$', manifest, re.MULTILINE)
interface = args.interface if args.interface is not None else int(observed.group(1)) if observed else 0
if interface <= 0:
    parser.error('A positive observed interface number is required; 0 is a placeholder')
output = root / args.output if args.output else root / 'dist' / 'ForeverXP-dev.zip'
output.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted((root / 'ForeverXP').rglob('*')):
        if not path.is_file() or path.suffix not in ('.lua', '.toc', '.tga'):
            continue
        if path.suffix == '.tga':
            archive.write(path, str(path.relative_to(root)))
            continue
        data = path.read_text()
        if path.suffix == '.toc':
            data = re.sub(r'^## Interface: .*$', f'## Interface: {interface}', data, flags=re.MULTILINE)
        archive.writestr(str(path.relative_to(root)), data)
print(output)
