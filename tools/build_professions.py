"""Generate original profession guide Lua from selected, attributed reference facts."""
import argparse
import json
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[1]
FACTS=ROOT/'Documentation/Reference/Professions1_300Facts.json'
OUTPUT=ROOT/'ForeverXP/Data/ProfessionGuides/Classic.lua'


def lua(value):
    if value is None:return 'nil'
    if isinstance(value,bool):return 'true' if value else 'false'
    if isinstance(value,(int,float)):return str(value)
    if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
    if isinstance(value,list):return '{'+', '.join(lua(v) for v in value)+'}'
    def key(k):
        if str(k).isdigit():return '['+str(k)+']'
        return k if re.fullmatch('[A-Za-z_][A-Za-z_0-9]*',k) else '['+lua(k)+']'
    return '{'+', '.join(key(k)+' = '+lua(v) for k,v in value.items())+'}'


def generate(facts):
    text='-- Generated from curated factual recipes and original skill stages by tools/build_professions.py.\n-- Reference content; live Forever profession validation pending.\n'
    text+='local guides = {\n'
    for guide in facts['guides']:
        text+='    {\n'
        for key,value in guide.items():
            if key in ('recipes','stages'):
                text+='        '+key+' = {\n'
                if isinstance(value,list):text+=''.join('            '+lua(row)+',\n' for row in value)
                else:text+=''.join('            ['+k+'] = '+lua(v)+',\n' for k,v in value.items())
                text+='        },\n'
            else:text+='        '+key+' = '+lua(value)+',\n'
        text+='    },\n'
    text+='}\nfor _,guide in ipairs(guides) do\n    local ok,err=ForeverXP.modules.RecipeDatabase:RegisterReferenceGuide(guide)\n    if not ok then ForeverXP:Print(guide.title.." rejected: "..tostring(err)) end\nend\n'
    return text


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    text=generate(json.loads(FACTS.read_text()))
    if args.check:
        if OUTPUT.read_text()!=text:raise SystemExit('Profession data differs; run python3 tools/build_professions.py')
        print('Profession data matches curated facts')
    else:
        OUTPUT.parent.mkdir(parents=True,exist_ok=True)
        OUTPUT.write_text(text)
        print(OUTPUT)
