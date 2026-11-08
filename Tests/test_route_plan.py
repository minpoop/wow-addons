import json
from pathlib import Path
import subprocess
import sys
import unittest
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]


class RoutePlanTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.plan=json.loads((ROOT/'Documentation/Reference/ElwynnWestfall1_20Plan.json').read_text())
        cls.facts=json.loads((ROOT/'Documentation/Reference/Alliance1_60Facts.json').read_text())

    def test_selected_quests_have_complete_ordered_phases_and_earlier_prerequisites(self):
        positions={}
        for n,stage in enumerate(self.plan['stages']):
            self.assertLessEqual(stage['maxLevel'],19)
            self.assertIn(stage['phase'],['accept','work','turn-in'])
            for quest in stage['quests']:
                self.assertNotIn((quest,stage['phase']),positions)
                positions[quest,stage['phase']]=n
        ids={quest for quest,_ in positions}
        self.assertEqual(len(ids),53);self.assertEqual(len(positions),159)
        self.assertNotIn(176,ids)
        for quest in ids:
            q=self.facts['quests'][str(quest)]
            self.assertFalse(q['optional']);self.assertIsNone(q['requiredClasses'])
            self.assertLess(positions[quest,'accept'],positions[quest,'work'])
            self.assertLess(positions[quest,'work'],positions[quest,'turn-in'])
            for prerequisite in q['prerequisitesAll']:
                self.assertIn(prerequisite,ids)
                self.assertLess(positions[prerequisite,'turn-in'],positions[quest,'accept'])
            if q['prerequisitesAny']:
                self.assertTrue(any(pre in ids and positions[pre,'turn-in']<positions[quest,'accept'] for pre in q['prerequisitesAny']))
            for endpoint in [q['start'],q['finish']]:
                actor=self.facts['actors'][endpoint]
                self.assertIn(actor['zone'],self.plan['zones'])

    def test_real_runtime_accepts_the_generated_profile_for_both_retained_campaigns(self):
        lua=LuaRuntime(unpack_returned_tuples=True)
        for line in (ROOT/'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):lua.execute((ROOT/'ForeverXP'/line).read_text())
        profile=lua.globals().ForeverXP.modules.RoutePlanner.plans[self.plan['id']]
        self.assertIsNotNone(profile)
        self.assertEqual(list(profile.guides.values()),self.plan['guides'])
        self.assertEqual(len(profile.stages),98)
        self.assertEqual(profile.verification,'reference-planned')

    def test_synthetic_benchmark_batches_one_outing_instead_of_three_without_claiming_live_time(self):
        result=subprocess.run([sys.executable,str(ROOT/'tools/route_benchmark.py')],capture_output=True,text=True,check=True)
        report=json.loads(result.stdout)
        self.assertIn('not measured Forever',report['scope'])
        old,new=report['quest_pool'],report['phase_batches']
        self.assertEqual(old['hub_crossings'],6);self.assertEqual(new['hub_crossings'],2)
        self.assertLess(new['map_units'],old['map_units'])
        self.assertEqual([row.split(':')[0] for row in new['actions'][:3]],['ACCEPT_QUEST']*3)
        self.assertEqual(report,json.loads((ROOT/'Documentation/Reference/RouteBatchBenchmark.json').read_text()))

    def test_route_plan_generation_is_reproducible(self):
        result=subprocess.run([sys.executable,str(ROOT/'tools/build_route_plan.py'),'--check'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()
