# Local route test reports — 0.8

The new report is an opt-in tool for testing an actual guide run. It records only
in this character's addon saves. Nothing is sent to a service, chat channel or
other player. `/fxp run report` prints into your own addon chat output.

1. Install the new folder and restart the client.
2. Use `/fxp route elwynn` to select the focused route, or continue an applicable
   automatic regional plan. Release an old manual pin with `/fxp leveling auto`
   if you want automatic batches.
3. Use `/fxp run start` or right-click → Route plan & run report → Start local test run.
4. Play normally. At a confusing recommendation, route wait or apparent XP gap,
   run `/fxp run report`. The recent quest/task/zone trace can help identify it.
5. `/fxp run stop` stops recording and retains the report. Starting another run
   retains one previous report. Current guide/profession progression is untouched.

The report includes observed level range, plan ID, sampled online time, measured
XP changes, unique positive in-run turn-ins, observed zone changes, route waits,
task changes and the last 12 trace entries. Up to 80 entries and 2,048 unique
turn-in IDs are retained per current run. Reports are private until you choose
to share their text; no character/account names are put in the report.

## Interpreting it correctly

- Online time uses readable GetTime samples and includes idle time. Loading/relog
  boundaries reset the baseline; offline time is not counted. It is not active
  speedrun time or measured travel time.
- XP uses guarded optional UnitXP/UnitXPMax/UnitLevel observations on interface
  16001. Same-level increases and a single rollover with a known previous
  threshold can be summed. Multi-level jumps, resets, unreadable data and loading
  discontinuities stay uncertain; they never generate invented XP. Ambiguous
  observations drop the baseline to prevent a later double count.
- XP includes kills and other sources. It is not attributed to a quest reward
  from event timing. A quest-XP table, server multiplier and full 1–20 budget are
  not inferred from these samples.
- A turn-in counts from a positive event or an accepted-to-positive-history
  transition observed during the run. Pre-existing history, disappearance and
  duplicate events do not inflate it. Repeat cycles of the same ID count once.
- Zone changes count observed zone-name changes, not every boundary crossed
  between samples. Task changes are planner decisions, not distance traveled.
- Route waits are deduplicated by plan/level/reason. Log-full and eligibility
  waits must be investigated; neither alone establishes an XP shortage.

XP events update the lightweight run counters without rescanning the quest log.
The normal coalesced guide refresh supplies quest/planner snapshots. There is no
new per-frame handler or polling timer. Recording does not alter selected tasks,
completion, deferrals, manual overrides or other characters.

Versioned malformed/future run records are retained rather than overwritten.
The existing explicit character reset retains a backup including these records;
ordinary start/stop/report commands never reset guide progression. Native XP,
clock/event contracts and long-session performance still need live validation.

## Useful playtest evidence

For a problem, capture the report plus the displayed quest, actual zone/level,
what you were doing, and whether the proposed quest was available. Record deaths,
long backtracking, missing drops/prerequisites and actual XP shortages separately.
A first 1–20 pass can reveal missing route branches and supply measured evidence
for the next content pass; offline tests cannot replace that run.
