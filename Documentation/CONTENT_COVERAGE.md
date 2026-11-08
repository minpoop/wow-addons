# Content coverage — 0.7

No authored route has been live-verified end to end on Forever. The reference
campaign pools contain 556 Alliance quests and 821 Horde quests, sharing 218
neutral records: **1,159 distinct quests** overall. Elwynn (34) and the earlier
Alliance 1–20 test (97) are subsets of Alliance 1–60; do not add them again.
Synthetic IDs in Tests/ and examples are never packaged as playable content.

| Target | Reference content | Live status |
| --- | --- | --- |
| Alliance shared leveling | 556 quests / 1,670 steps; 12 chapters through 60 | Full playthrough and XP budget pending |
| Elwynn shared route | 34 quests / 113 steps; retained area guide | User reports catch-up works; full route pending |
| Horde shared leveling | 821 quests / 2,465 steps; 12 chapters through 60 | All content needs live validation |
| Horde starts | Orc/Troll Durotar, Tauren Mulgore, Undead Tirisfal | Offline race/level tests only |
| Class tasks / dungeon routes / flight network | No authored coverage | Missing |
| Professions 1–300 | 12 guides, 132 recipes, 146 stages | Live skill/rank/knowledge/material checks pending |
| Gathering | Four resource/area guides; no surveyed loops | No measured spawn routes |
| Custom Forever content and races | Unknown | Needs server observations |

Selected facts, source hashes and scope are in Reference/Alliance1_60.md,
Reference/Horde1_60.md and Reference/Professions1_300.md. For live verification,
record client build/interface, server, date, quest/recipe IDs and actual outcomes.
Schema and synthetic progression tests establish structure and algorithm behavior;
they do not establish server availability, enough XP, travel efficiency or caps.


Version 0.8 adds a planned 53-quest Elwynn–Westfall–Redridge itinerary using existing
quest IDs (no increase in distinct coverage), with 159 phases and 98 batches.
This is a shared Human-region 1–20 segment, not all starting races, Horde or a
measured XP budget. The synthetic three-quest comparison and private opt-in run
reports support testing; a complete live route remains pending. See ROUTE_PLANNING.md.
