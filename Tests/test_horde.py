import json
from pathlib import Path
import subprocess
import sys
import unittest
from lupa.lua51 import LuaRuntime
ROOT=Path(__file__).resolve().parents[1]


class HordeFactsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.facts=json.loads((ROOT/'Documentation/Reference/Horde1_60Facts.json').read_text())
        cls.lua=LuaRuntime(unpack_returned_tuples=True);cls.lua.execute('print=function() end')
        for line in (ROOT/'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):cls.lua.execute((ROOT/'ForeverXP'/line).read_text())
        cls.guide=cls.lua.globals().ForeverXP.modules.GuideEngine.guides['horde-levels-1-60']

    def test_every_quest_matches_reference_levels_race_masks_and_phase_locations(self):
        facts,guide=self.facts,self.guide
        self.assertEqual(len(facts['quests']),821);self.assertEqual(len(guide.steps),2465)
        self.assertEqual(facts['quests']['363']['allowedRaces'],['Scourge'])
        self.assertEqual(set(facts['quests']['4641']['allowedRaces']),{'Orc','Troll'})
        seen=set()
        for i in range(1,len(guide.steps)+1):
            step=guide.steps[i]
            if not step.questId:continue
            q=facts['quests'][str(step.questId)];seen.add(str(step.questId))
            self.assertIsNone(q['requiredClasses'])
            self.assertFalse((q['requiredRaces'] or 0)&~178)
            self.assertEqual(step.questTitle,q['title']);self.assertEqual(step.questLevel,q['questLevel'])
            self.assertEqual(step.minLevel,max(1,q['referenceMinimumLevel']))
            if step.type=='ACCEPT_QUEST':
                self.assertEqual(list(step.allowedRaces.values()) if step.allowedRaces else [],q.get('allowedRaces',[]))
                self.assertEqual(list(step.prerequisiteQuestsAny.values()),q['prerequisitesAny'])
                self.assertEqual(list(step.exclusiveQuests.values()),q['exclusiveQuests'])
            if step.type in ('ACCEPT_QUEST','TURN_IN_QUEST'):
                actor=facts['actors'].get(q['start' if step.type=='ACCEPT_QUEST' else 'finish'])
                if actor and actor['position']:
                    self.assertEqual(step.waypoint.zone,actor['zone'])
                    self.assertAlmostEqual(step.waypoint.x*100,actor['position'][0],places=3)
                    self.assertAlmostEqual(step.waypoint.y*100,actor['position'][1],places=3)
                else:self.assertIsNone(step.waypoint)
        self.assertEqual(seen,set(facts['quests']))

    def test_every_later_band_has_multiple_non_optional_choices(self):
        for first in range(1,60,5):
            choices=[q for q in self.facts['quests'].values() if first<=q['questLevel']<first+5 and not q['optional']]
            self.assertGreaterEqual(len(choices),10,first)
        names={q['zone'] for q in self.facts['quests'].values()}
        self.assertTrue({'Durotar','Mulgore','Tirisfal Glades','The Barrens','Silverpine Forest','Winterspring','Silithus'}<=names)

    def test_horde_generation_is_reproducible(self):
        result=subprocess.run([sys.executable,str(ROOT/'tools/build_leveling.py'),'--faction','Horde','--check'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()
