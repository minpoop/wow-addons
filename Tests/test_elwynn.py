import json
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class ElwynnReferenceTests(unittest.TestCase):
    def test_authored_route_matches_curated_reference_facts(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('print=function() end')
        for line in (ROOT / 'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):
                lua.execute((ROOT / 'ForeverXP' / line).read_text())
        guide = lua.globals().ForeverXP.modules.GuideEngine.guides['elwynn-forest-shared']
        facts = json.loads((ROOT / 'Documentation/Reference/ElwynnFacts.json').read_text())
        encountered = set()
        previous = set()
        for step in guide.steps.values():
            for pre in step.prerequisites.values() if step.prerequisites else []:
                self.assertIn(pre, previous, step.id)
            previous.add(step.id)
            if not step.questId:
                continue
            encountered.add(str(step.questId))
            fact = facts['quests'][str(step.questId)]
            self.assertIsNone(fact['requiredClasses'])
            self.assertIn(fact['title'], step.text)
            if step.type == 'COMPLETE_QUEST':
                continue
            actor = fact['start' if step.type == 'ACCEPT_QUEST' else 'finish']
            entity = facts['npcs' if actor['kind'] == 'npc' else 'objects'][str(actor['id'])]
            self.assertIn(entity['name'], step.text)
            if step.type == 'ACCEPT_QUEST':
                self.assertEqual(step.minLevel, fact['minimumLevel'])
                self.assertEqual(set(step.prerequisites.values()),
                                 {f'quest-{pre}-turn-in' for pre in fact['prerequisites']})
            if entity['position']:
                self.assertEqual(step.waypoint.verification, 'reference-reviewed')
                self.assertAlmostEqual(step.waypoint.x * 100, entity['position'][0], places=3)
                self.assertAlmostEqual(step.waypoint.y * 100, entity['position'][1], places=3)
        self.assertEqual(encountered, set(facts['quests']))
        self.assertEqual(len(encountered), 34)


if __name__ == '__main__':
    unittest.main()
