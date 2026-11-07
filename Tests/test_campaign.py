import json
from pathlib import Path
import unittest
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


class CampaignFactsTests(unittest.TestCase):
    def test_curated_quest_levels_eligibility_prerequisites_and_waypoints(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('print=function() end')
        for line in (ROOT / 'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):
                lua.execute((ROOT / 'ForeverXP' / line).read_text())
        guide = lua.globals().ForeverXP.modules.GuideEngine.guides['alliance-levels-1-20']
        facts = json.loads((ROOT / 'Documentation/Reference/Alliance1_20Facts.json').read_text())
        encountered = set()
        previous = set()
        for step in guide.steps.values():
            for pre in step.prerequisites.values() if step.prerequisites else []:
                self.assertIn(pre, previous)
            previous.add(step.id)
            if not step.questId:
                continue
            key = str(step.questId)
            encountered.add(key)
            fact = facts['quests'][key]
            self.assertIsNone(fact['requiredClasses'])
            self.assertEqual(step.questTitle, fact['title'])
            self.assertEqual(step.questLevel, fact['questLevel'])
            self.assertEqual(step.minLevel, max(1, fact['referenceMinimumLevel']))
            self.assertEqual(step.optional, fact['optional'])
            if step.type == 'ACCEPT_QUEST':
                self.assertEqual(set(step.prerequisites.values()),
                                 {f'quest-{pre}-turn-in' for pre in fact['prerequisites']})
            if step.type != 'COMPLETE_QUEST' or fact['delivery']:
                actor = facts['actors'][fact['start' if step.type == 'ACCEPT_QUEST' else 'finish']]
                if actor['position']:
                    self.assertEqual(step.waypoint.zone, actor['zone'])
                    self.assertEqual(step.waypoint.verification, 'reference-reviewed')
                    self.assertAlmostEqual(step.waypoint.x * 100, actor['position'][0], places=3)
                    self.assertAlmostEqual(step.waypoint.y * 100, actor['position'][1], places=3)
                else:
                    self.assertIsNone(step.waypoint)
        self.assertEqual(encountered, set(facts['quests']))
        self.assertEqual(len(encountered), 97)


if __name__ == '__main__':
    unittest.main()
