"""Rebuild the original faction campaigns from curated, pinned reference facts."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FACTS = ROOT / 'Documentation/Reference/Alliance1_60Facts.json'
OUTPUT = ROOT / 'ForeverXP/Data/QuestGuides/Alliance/Levels1_60.lua'
CHAPTERS = [
    (1, 4, 'A letter in the fog', 'Northshire introductions and shared starting work.'),
    (5, 9, 'Beyond the abbey', 'Goldshire and Elwynn; move on as quests fall behind your level.'),
    (10, 14, 'The first crossing', 'Westfall and Loch Modan provide common Alliance alternatives.'),
    (15, 19, 'Roads diverge', 'Westfall, Loch Modan and early Redridge chains.'),
    (20, 24, 'The darkened road', 'Duskwood, Wetlands and later Redridge work.'),
    (25, 29, 'Watchfires', 'Duskwood and Wetlands; Hillsbrad opens the next stretch.'),
    (30, 34, 'Beyond familiar ground', 'Stranglethorn, Hillsbrad, Arathi, Desolace and the Shimmering Flats.'),
    (35, 39, 'Distant signals', 'Stranglethorn, Badlands, Dustwallow and Swamp of Sorrows.'),
    (40, 44, 'Heat on the horizon', 'Tanaris, Feralas and the Hinterlands.'),
    (45, 49, 'Ash and brass', 'Tanaris, Feralas, Searing Gorge, Azshara and Blasted Lands.'),
    (50, 54, 'Through the cinders', "Un'Goro, Felwood, Burning Steppes and Western Plaguelands."),
    (55, 59, 'The last watch', 'Winterspring, Eastern Plaguelands and Silithus lead toward level 60.'),
]

HORDE_CHAPTERS = [
    (1,4,'First steps','Durotar, Mulgore or Tirisfal, based on your race and location.'),
    (5,9,'Beyond the camp','Shared starting-zone tasks; class-specific training stays separate.'),
    (10,14,'A wider world','The Barrens and Silverpine offer suitable next tasks.'),
    (15,19,'Between outposts','The Barrens, Silverpine, Stonetalon and Ashenvale.'),
    (20,24,'Borderlands','The Barrens, Hillsbrad, Ashenvale and Thousand Needles.'),
    (25,29,'The long watch','Hillsbrad, Thousand Needles and Stonetalon.'),
    (30,34,'Distant roads','Arathi, Desolace, Stranglethorn and the Shimmering Flats.'),
    (35,39,'Unfamiliar ground','Stranglethorn, Dustwallow, Desolace and Swamp of Sorrows.'),
    (40,44,'The dry frontier','Feralas, Tanaris and the Hinterlands.'),
    (45,49,'Ash and sand','Tanaris, Feralas, Searing Gorge and Azshara.'),
    (50,54,'Into the wilderness',"Un'Goro, Felwood, Burning Steppes and Western Plaguelands."),
    (55,59,'The last chapter','Winterspring, Eastern Plaguelands and Silithus.'),
]


def lua(value):
    if value is None:
        return 'nil'
    if isinstance(value, bool):
        return 'true' if value else 'false'
    if isinstance(value, (int, float)):
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return '{' + ', '.join(lua(v) for v in value) + '}'
    return '{' + ', '.join(k + ' = ' + lua(v) for k, v in value.items()) + '}'


def generate(facts, faction="Alliance"):
    chapters=CHAPTERS if faction=="Alliance" else HORDE_CHAPTERS
    quests, actors = facts['quests'], facts['actors']
    remaining = list(quests)
    ordered = []
    while remaining:
        available = [key for key in remaining if
                     all(str(p) in ordered for p in quests[key]['prerequisitesAll'] if str(p) in quests) and
                     all(str(p) in ordered for p in quests[key]['prerequisitesAny'] if str(p) in quests)]
        if not available:
            raise ValueError('Cyclic or incomplete selected prerequisite facts')
        for key in available:
            ordered.append(key)
            remaining.remove(key)
    guide = dict(id=faction.lower()+'-levels-1-60', title=faction+' 1–60 · level-aware guide',
                 faction=faction, minLevel=1, maxLevel=60,
                 verification='reference-reviewed', source=facts['source'],
                 campaign=dict(targetLevel=60, maxQuestLag=3, maxQuestLead=2, zonePreference=25,
                               chapters=[dict(minLevel=a, maxLevel=b, title=t, text=s) for a,b,t,s in chapters]))
    if faction=="Horde":guide["campaign"]["homeZones"]={"Orc":"Durotar","Troll":"Durotar","Tauren":"Mulgore","Scourge":"Tirisfal Glades"}
    steps = [dict(id='campaign-intro', type='MANUAL_INSTRUCTION',
                  text=faction+' 1–60: recommendations follow your level and observed quests. Reference locations need checking on Forever. Older unfinished work stays saved.')]

    def waypoint(place):
        if place and place.get('zone') and place.get('position'):
            x,y = place['position']
            return dict(zone=place['zone'], x=round(x/100, 5), y=round(y/100, 5), verification='reference-reviewed')

    for key in ordered:
        q = quests[key]
        start = actors.get(q['start'])
        finish = actors[q['finish']]
        objectives = q['objectives']
        names = [actors[o['actor']]['name'] if 'actor' in o else o['name'] for o in objectives]
        lead = next((actors[o.get('actor') or o.get('source')] for o in objectives
                     if (o.get('actor') or o.get('source')) and actors[o.get('actor') or o.get('source')]['position']), None)
        for phase, kind in [('accept','ACCEPT_QUEST'),('complete','COMPLETE_QUEST'),('turn-in','TURN_IN_QUEST')]:
            s = dict(id=f'quest-{key}-{phase}', type=kind, questId=int(key), questTitle=q['title'],
                     questLevel=q['questLevel'], minLevel=q['minimumLevel'], optional=q['optional'])
            place = None
            if phase == 'accept':
                s['prerequisites'] = [f'quest-{p}-turn-in' for p in q['prerequisitesAll'] if str(p) in quests]
                external=[p for p in q['prerequisitesAll'] if str(p) not in quests]
                if external:s['prerequisiteQuestsAll']=external
                if q.get('allowedRaces'):s['allowedRaces']=q['allowedRaces']
                s['prerequisiteQuestsAny'] = q['prerequisitesAny']
                s['exclusiveQuests'] = q['exclusiveQuests']
                if start:
                    s['text'] = f"Accept {q['title']} from {start['name']}."
                    s['npcId' if start['kind']=='npc' else 'objectId'] = start['id']
                    place = start
                else:
                    item=q['startItem']
                    s['text'] = f"Find {item['name']} and use it to start {q['title']}. This optional item-started quest depends on finding its item."
            elif phase == 'turn-in':
                s['prerequisites'] = [f'quest-{key}-complete']
                s['text'] = f"Turn in {q['title']} at {finish['name']}."
                s['npcId' if finish['kind']=='npc' else 'objectId'] = finish['id']
                place = finish
            else:
                s['prerequisites'] = [f'quest-{key}-accept']
                if names:
                    summary = ', '.join(names[:2]) + (' and the other listed targets' if len(names)>2 else '')
                    s['text'] = f"Work on {q['title']}: {summary}. Follow your quest log for exact tasks and totals."
                    place = lead
                elif q.get('explore'):
                    s['text'] = f"Explore the reference area for {q['title']}; follow the quest log for the required action."
                    place = q['explore']
                else:
                    s['text'] = f"Follow the quest log for {q['title']}; check in with {finish['name']}."
                    place = finish
            if q['optional']:
                s['text'] += ' Optional: check difficulty and any special requirements before proceeding.'
            point = waypoint(place)
            if point:
                s['waypoint'] = point
            s['zone'] = (place or {}).get('zone') or q['zone']
            steps.append(s)
    steps.append(dict(id='campaign-target-60', type='REACH_LEVEL', level=60,
                      text='Reach level 60. Unfinished quests remain saved; no quests are abandoned automatically.'))
    output = '-- Generated by tools/build_leveling.py from selected reference facts. Original instructions; live validation pending.\nlocal guide = {\n'
    output += ''.join('    '+k+' = '+lua(v)+',\n' for k,v in guide.items())
    output += '    steps = {\n' + ''.join('        '+lua(s)+',\n' for s in steps) + '    },\n}\n'
    output += 'local ok,err=ForeverXP.modules.GuideEngine:RegisterReferenceGuide(guide)\nif not ok then ForeverXP:Print("PLACEHOLDER 1–60 guide rejected: "..tostring(err)) end\n'
    return output.replace('PLACEHOLDER',faction)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Fail if generated content differs')
    parser.add_argument('--faction',choices=['Alliance','Horde'],default='Alliance')
    args = parser.parse_args()
    facts_path=FACTS if args.faction=='Alliance' else ROOT/'Documentation/Reference/Horde1_60Facts.json'
    output_path=OUTPUT if args.faction=='Alliance' else ROOT/'ForeverXP/Data/QuestGuides/Horde/Levels1_60.lua'
    content = generate(json.loads(facts_path.read_text()),args.faction)
    if args.check:
        if output_path.read_text() != content:
            raise SystemExit('Campaign data differs; run python3 tools/build_leveling.py')
        print('Campaign data matches curated facts')
    else:
        output_path.parent.mkdir(parents=True,exist_ok=True)
        output_path.write_text(content)
        print(output_path)
