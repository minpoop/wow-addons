"""Generate original quest advice from selected, pinned reference facts."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FACTS = ROOT / 'Documentation/Reference/QuestAdviceFacts.json'
OUTPUT = ROOT / 'ForeverXP/Data/QuestAdvice/Classic.lua'


def literal(value):
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, int):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return '{' + ', '.join(literal(v) for v in value) + '}'
    return '{' + ', '.join(k + ' = ' + literal(v) for k, v in value.items()) + '}'


def generate(facts):
    lines = ['-- Generated reference advice; original tips. Forever live validation pending.',
             'local records = {']
    for key in sorted(facts['quests'], key=int):
        lines.append('    [' + key + '] = ' + literal(facts['quests'][key]) + ',')
    lines += ['}', 'local ok,err=ForeverXP.modules.QuestAdvice:RegisterReference(records)',
              'if not ok then ForeverXP:Print("Quest advice rejected: "..tostring(err)) end', '']
    return '\n'.join(lines)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    content = generate(json.loads(FACTS.read_text()))
    if args.check:
        if OUTPUT.read_text() != content:
            raise SystemExit('Quest advice differs; run python3 tools/build_quest_advice.py')
        print('Quest advice matches selected facts')
    else:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(content)
        print(OUTPUT)
