import json
from pathlib import Path
import subprocess
import sys
import unittest
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]


class ProfessionFactsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.facts=json.loads((ROOT/'Documentation/Reference/Professions1_300Facts.json').read_text())
        cls.lua=LuaRuntime(unpack_returned_tuples=True)
        cls.lua.execute('print=function() end')
        for line in (ROOT/'ForeverXP/ForeverXP.toc').read_text().splitlines():
            if line.endswith('.lua'):cls.lua.execute((ROOT/'ForeverXP'/line).read_text())
        cls.catalogs=cls.lua.globals().ForeverXP.modules.RecipeDatabase.catalogs

    def test_every_guide_recipe_and_skill_band_matches_selected_facts(self):
        self.assertEqual(len(self.facts['guides']),12)
        total_recipes=total_stages=0
        for fact in self.facts['guides']:
            guide=self.catalogs[fact['id']]
            self.assertIsNotNone(guide,fact['id'])
            self.assertEqual(guide.skillId,fact['skillId'])
            self.assertEqual(guide.verification,'reference-reviewed')
            self.assertEqual(list(guide.rankSpells.values()),fact['rankSpells'])
            edge=1
            for i,stage in enumerate(fact['stages'],1):
                actual=guide.stages[i]
                self.assertEqual(stage['from'],edge)
                self.assertEqual(actual['from'],edge)
                self.assertEqual(actual.to,stage['to'])
                self.assertEqual(actual.text,stage['text'])
                edge=stage['to'];total_stages+=1
                if fact['kind']=='craft':
                    self.assertEqual(list(actual.choices.values()),stage['choices'])
                    for recipe in stage['choices']:self.assertLessEqual(fact['recipes'][str(recipe)]['minimum'],stage['from'])
                else:self.assertEqual(list(actual.resources.values()),stage['resources'])
            self.assertEqual(edge,300)
            for key,recipe in fact['recipes'].items():
                actual=guide.recipes[int(key)]
                self.assertEqual(actual.name,recipe['name'])
                self.assertEqual(actual.minimum,recipe['minimum'])
                self.assertEqual(dict(actual.inputs.items()),{int(k):v for k,v in recipe['inputs'].items()})
                self.assertEqual(actual.output,recipe['output'])
                self.assertEqual(actual.outputCount,recipe['outputCount'])
                self.assertEqual(list(actual.tools.values()),recipe['tools'])
                total_recipes+=1
        self.assertEqual(total_recipes,132);self.assertEqual(total_stages,146)

    def test_selected_reagents_outputs_and_recipe_eligibility_are_explicit(self):
        guides={g['id']:g for g in self.facts['guides']}
        healing=guides['alchemy']['recipes']['2330']
        self.assertEqual(healing['inputs'],{'2447':1,'765':1,'3371':1})
        self.assertEqual(healing['output'],118)
        self.assertEqual(guides['tailoring']['recipes']['2963']['inputs'],{'2589':2})
        self.assertEqual(guides['tailoring']['recipes']['2963']['output'],2996)
        self.assertEqual(guides['first-aid']['recipes']['18630']['minimum'],290)
        self.assertEqual(guides['engineering']['recipes']['19800']['minimum'],285)
        self.assertEqual(self.facts['archiveSHA256'],'4f92db520868ab4e566726f68b5b2e380ae781209beaf22237b4f7f04600d0c0')
        for guide in guides.values():
            for recipe in guide['recipes'].values():
                self.assertTrue(recipe['acquisition'])
                self.assertTrue(all(int(k)>0 and v>0 for k,v in recipe['inputs'].items()))

    def test_generated_profession_guides_are_reproducible(self):
        result=subprocess.run([sys.executable,str(ROOT/'tools/build_professions.py'),'--check'],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()
