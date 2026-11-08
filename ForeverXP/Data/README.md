# Server content

QuestGuides/Alliance/Elwynn.lua is the first original reference route, explicitly
not live-verified on Forever. It uses curated Classic facts with provenance in
Documentation/Reference/Elwynn.md. Do not promote it based on mocked tests.

Add independently authored, live-verified content under QuestGuides/Alliance, QuestGuides/Horde,
ProfessionGuides, GatheringRoutes and Trainers only after following the root
format documents and Documentation/CONTENT_COVERAGE.md. Add explicit TOC entries
after the relevant engine modules and before Bootstrap. Do not copy proprietary
guides or promote synthetic test fixtures to production content.

QuestGuides/Alliance/Levels1_20.lua adds a level-aware Alliance reference playtest
with 97 quests (including Elwynn). Evidence and curated facts are in
Documentation/Reference/Alliance1_20.md. The pool is class-independent in the
reference; XP coverage and server validity still need live validation.

QuestGuides/Alliance/Levels1_60.lua is the expanded default campaign: 556 selected
quests, including the original 97; no class restriction in those source facts.
Generate it with tools/build_leveling.py from Alliance1_60Facts.json. Chapter
summaries, source hashes, optional content and live-validation scope are recorded
in Documentation/Reference/Alliance1_60.md. Do not equate level-range content with
a measured XP budget or a completed Forever playthrough.

ProfessionGuides/Classic.lua adds 12 reference guides covering skill 1–300.
Generate it from the selected Professions1_300Facts.json using tools/build_professions.py.
It contains 132 recipes and 146 authored stages, with no manufactured skill-up
probability. See Documentation/Reference/Professions1_300.md for provenance and
live-validation scope. No downloaded SQL database is included in the addon.
