"""Generate the original 1–20 phase itinerary from authored reference data."""
import argparse
import json
from pathlib import Path
from build_quest_advice import literal

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'Documentation/Reference/ElwynnWestfall1_20Plan.json'
OUTPUT=ROOT/'ForeverXP/Data/RoutePlans/ElwynnWestfall1_20.lua'


def generate(profile):
    lines=['-- Original reference phase itinerary; live XP/travel validation pending.','local plan = {']
    lines += ['    '+key+' = '+literal(value)+',' for key,value in profile.items() if key!='stages']
    lines += ['    stages = {']+['        '+literal(stage)+',' for stage in profile['stages']]+['    },','}']
    lines += ['local ok,err=ForeverXP.modules.RoutePlanner:Register(plan)',
              'if not ok then ForeverXP:Print("Route plan rejected: "..tostring(err)) end','']
    return '\n'.join(lines)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    content=generate(json.loads(SOURCE.read_text()))
    if args.check:
        if OUTPUT.read_text()!=content:raise SystemExit('Route plan differs; run python3 tools/build_route_plan.py')
        print('Route plan matches authored data')
    else:
        OUTPUT.parent.mkdir(parents=True,exist_ok=True)
        OUTPUT.write_text(content)
        print(OUTPUT)
