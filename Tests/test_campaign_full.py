import json
from pathlib import Path
import subprocess
import sys
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class FullCampaignFactsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.facts = json.loads((ROOT/'Documentation/Reference/Alliance1_60Facts.json').read_text())
        cls.lua = LuaRuntime(unpack_returned_tuples=True)
        cls.lua.execute('print=function() end')
        for line in (ROOT/'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):
                cls.lua.execute((ROOT/'ForeverXP'/line).read_text())
        cls.guide = cls.lua.globals().ForeverXP.modules.GuideEngine.guides['alliance-levels-1-60']

    def test_every_phase_matches_curated_facts_and_selected_actor_points(self):
        facts, guide = self.facts, self.guide
        self.assertEqual(len(facts['quests']),556)
        self.assertEqual(len(guide.steps),1670)
        seen, previous = set(), set()
        for i in range(1,len(guide.steps)+1):
            step=guide.steps[i]
            for pre in step.prerequisites.values() if step.prerequisites else []:
                self.assertIn(pre,previous)
            previous.add(step.id)
            if not step.questId:
                continue
            key=str(step.questId);seen.add(key);q=facts['quests'][key]
            self.assertIsNone(q['requiredClasses'])
            self.assertIn(q['requiredRaces'],(None,0,77))
            self.assertEqual(step.questTitle,q['title'])
            self.assertEqual(step.questLevel,q['questLevel'])
            self.assertEqual(step.minLevel,max(1,q['referenceMinimumLevel']))
            self.assertEqual(step.optional,q['optional'])
            if step.type=='ACCEPT_QUEST':
                self.assertEqual(set(step.prerequisites.values()),{f'quest-{p}-turn-in' for p in q['prerequisitesAll']})
                self.assertEqual(list(step.prerequisiteQuestsAny.values()),q['prerequisitesAny'])
                self.assertEqual(list(step.exclusiveQuests.values()),q['exclusiveQuests'])
            if step.type in ('ACCEPT_QUEST','TURN_IN_QUEST'):
                actor=facts['actors'].get(q['start' if step.type=='ACCEPT_QUEST' else 'finish'])
                if actor:
                    self.assertIn(actor['name'],step.text)
                    self.assertEqual(step.npcId if actor['kind']=='npc' else step.objectId,actor['id'])
                    if actor['position']:
                        self.assertEqual(step.waypoint.zone,actor['zone'])
                        self.assertAlmostEqual(step.waypoint.x*100,actor['position'][0],places=3)
                        self.assertAlmostEqual(step.waypoint.y*100,actor['position'][1],places=3)
                    else:
                        self.assertIsNone(step.waypoint)
                else:
                    self.assertTrue(step.optional)
                    self.assertIn(q['startItem']['name'],step.text)
                    self.assertIsNone(step.waypoint)
            if step.waypoint:
                self.assertEqual(step.waypoint.verification,'reference-reviewed')
                self.assertTrue(0<=step.waypoint.x<=1 and 0<=step.waypoint.y<=1)
        self.assertEqual(seen,set(facts['quests']))

    def test_original_quests_are_retained_and_every_later_band_has_substantial_content(self):
        old=json.loads((ROOT/'Documentation/Reference/Alliance1_20Facts.json').read_text())
        for key,q in old['quests'].items():
            new=self.facts['quests'][key]
            for field in ('title','questLevel','minimumLevel','requiredClasses','requiredRaces'):
                self.assertEqual(new[field],q[field])
        for minimum in range(20,60,5):
            eligible=[q for q in self.facts['quests'].values() if not q['optional'] and minimum<=q['questLevel']<=minimum+4]
            self.assertGreaterEqual(len(eligible),20,f'Thin band {minimum}')
        self.assertEqual(self.facts['sourceHashes']['items'],'987d037b6df94d5b0b1dc326a1670581e3abb952736a4ae055fd9f161328b71c')

    def test_generated_content_is_reproducible(self):
        result=subprocess.run([sys.executable,str(ROOT/'tools/build_leveling.py'),'--check'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr+result.stdout)


if __name__=='__main__':
    unittest.main()
