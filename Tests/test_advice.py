import json
from pathlib import Path
import subprocess
import sys
import unittest
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]


class QuestAdviceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.facts=json.loads((ROOT/'Documentation/Reference/QuestAdviceFacts.json').read_text())
        cls.alliance=json.loads((ROOT/'Documentation/Reference/Alliance1_60Facts.json').read_text())
        cls.horde=json.loads((ROOT/'Documentation/Reference/Horde1_60Facts.json').read_text())
        cls.lua=LuaRuntime(unpack_returned_tuples=True)
        for line in (ROOT/'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):cls.lua.execute((ROOT/'ForeverXP'/line).read_text())
        cls.records=cls.lua.globals().ForeverXP.modules.QuestAdvice.records

    def test_reference_coverage_and_runtime_records_match_selected_fact_pools(self):
        selected={**self.alliance['quests'],**self.horde['quests']}
        self.assertEqual(set(selected),set(self.facts['quests']))
        self.assertEqual(self.facts['sourceHashes'],self.alliance['sourceHashes'])
        self.assertEqual(len(list(self.records.keys())),1159)
        for key,q in self.facts['quests'].items():
            self.assertEqual(q['title'],selected[key]['title'])
            self.assertEqual(q['questLevel'],selected[key]['questLevel'])
            for field,value in q.items():
                actual=self.records[int(key)][field]
                if isinstance(value,list):actual=list(actual.values())
                self.assertEqual(actual,value,(key,field))

    def test_elite_evidence_identifies_selected_actors_and_keeps_event_kinds_distinct(self):
        for key,evidence in self.facts['hazardEvidence'].items():
            pool=self.horde if key in self.horde['quests'] else self.alliance
            selected=pool['quests'][key]
            actors=pool['actors']
            advice=self.facts['quests'][key]
            for elite in evidence.get('eliteActors',[]):
                self.assertIn(elite['rank'],[1,2,3])
                self.assertTrue(any(actors.get(o.get('actor') or o.get('source'),{}).get('id')==elite['npcId'] for o in selected['objectives']))
                self.assertIn(advice[elite['role']],[row['name'] for row in evidence['eliteActors'] if row['role']==elite['role']])
            if advice.get('event'):
                self.assertTrue(evidence['specialFlags']&2)
                self.assertFalse(advice.get('escort',False))
                self.assertNotEqual(advice['kind'],'explore')
            if advice.get('escort'):self.assertTrue(evidence['escortObjective'])
        self.assertNotIn('eliteSource',self.facts['quests']['87'])
        self.assertEqual(self.facts['quests']['176']['eliteSource'],'Hogger')
        self.assertEqual(sum(bool(q.get('tips')) for q in self.facts['quests'].values()),17)

    def test_advice_generation_is_reproducible(self):
        result=subprocess.run([sys.executable,str(ROOT/'tools/build_quest_advice.py'),'--check'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()
