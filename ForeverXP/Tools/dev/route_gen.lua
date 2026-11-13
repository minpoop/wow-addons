-- Route generator: builds guide files from WoW Forever's quest data (QuestieDB) and a zone plan.
--   lua -e "arg_root='.'; qdb_root='/path/to/QuestieDB'; plan_file='Tools/dev/horde_plan.lua'" Tools/dev/route_gen.lua
-- For each segment of the plan it takes the zone's quests for the faction and level window, then simulates
-- playing them: accept everything available (grouped by quest giver, nearest first, quest log capped), do the
-- objectives (nearest first), hand in (grouped by NPC), and repeat while hand-ins unlock follow-ups. Only quests
-- whose giver and turn-in NPC are friendly to the faction and stand in the zone (or its listed extra areas) are
-- used; elite objectives, dungeon quests, class quests and item-started quests are left out. Step text is written
-- from the objective data, in our own words. Output is Lua guide files; check them with forever_check.lua.
assert(arg_root and qdb_root and plan_file, "set arg_root, qdb_root and plan_file")
skip_check = true
local F = dofile(arg_root .. "/Tools/dev/forever_check.lua")
local Q, N, O, I, AREA = F.quests, F.npcs, F.objects, F.items, F.area
local K, NK, OK, IK = F.keys, F.npcKeys, F.objectKeys, F.itemKeys
local plan = dofile(arg_root .. "/" .. plan_file)

-- quest XP (Questie's QuestXP data for WoW Forever) and the XP needed per level, for the coverage report
local XP = {}
do
  local mods = {}
  local old = QuestieLoader
  QuestieLoader = { ImportModule = function(_, name) mods[name] = mods[name] or {}; return mods[name] end }
  for _, f in ipairs({ "/support/Forever/QuestXP/xpDB-classic.lua", "/support/Forever/QuestXP/xpDB-traces.lua" }) do
    local fh = io.open(qdb_root .. f, "r")
    if fh then local t = fh:read("*a"); fh:close(); pcall(function() assert(load(t))() end) end
  end
  QuestieLoader = old
  local db = mods.QuestXP and mods.QuestXP.db or {}
  for id, v in pairs(db) do if type(v) == "table" then XP[id] = v[2] end end
end
local LEVEL_XP = { 400, 900, 1400, 2100, 2800, 3600, 4500, 5400, 6500, 7600, 8800, 10100, 11400, 12900, 14400, 16000,
  17700, 19400, 21300, 23200, 25200, 27300, 29400, 31700, 34000, 36400, 38900, 41400, 44300, 47400, 50800, 54500, 58600,
  62800, 67100, 71600, 76100, 80800, 85700, 90700, 95800, 101000, 106300, 111800, 117500, 123200, 129100, 135100,
  141200, 147500, 153900, 160400, 167100, 173900, 180800, 187900, 195000, 202300, 209800 }

local FACTION = plan.faction or "Horde"
local FLETTER = FACTION == "Horde" and "H" or "A"
local FACTION_BITS = FACTION == "Horde" and 178 or 77
local RACEBIT = { Human = 1, Orc = 2, Dwarf = 4, NightElf = 8, Scourge = 16, Tauren = 32, Gnome = 64, Troll = 128 }
local LOG_CAP = plan.logCap or 15

local function band(a, b) return math.floor(a) & math.floor(b) end

local function raceOK(q, races)
  local low = (q[K.requiredRaces] or 0) % 256
  if low == 0 then return true end
  if band(low, FACTION_BITS) == 0 then return false end
  if races then
    for _, r in ipairs(races) do if band(low, RACEBIT[r] or 0) ~= 0 then return true end end
    return false
  end
  return band(low, FACTION_BITS) == FACTION_BITS
end

local function friendly(npc)
  local f = npc and npc[NK.friendlyToFaction]
  return type(f) == "string" and f:find(FLETTER, 1, true) ~= nil
end

local function inAreas(spawns, areas)
  if type(spawns) ~= "table" then return nil end
  for _, a in ipairs(areas) do
    local list = spawns[a]
    if type(list) == "table" and list[1] and list[1][1] and list[1][1] > 0 then return a, list end
  end
end

-- the spot for a list of spawn points: the median, so a few outliers don't drag it into the void
local function spot(points)
  if #points == 0 then return nil end
  local xs, ys = {}, {}
  for _, p in ipairs(points) do xs[#xs + 1] = p[1]; ys[#ys + 1] = p[2] end
  table.sort(xs); table.sort(ys)
  local m = math.floor((#xs + 1) / 2)
  return { math.floor(xs[m] * 10 + 0.5) / 10, math.floor(ys[m] * 10 + 0.5) / 10 }
end

local function npcName(id) return N[id] and N[id][NK.name] end

-- Where a quest is given / taken, inside the segment's areas. Returns { id, name, area, x, y, kind } or nil.
local function endpoint(q, which, areas)
  local by = q[which == "start" and K.startedBy or K.finishedBy] or {}
  -- started by an item that drops in the zone: "loot it and right-click it"
  if which == "start" and by[3] and #(by[3]) > 0 and not (by[1] and #by[1] > 0) then
    for _, iid in ipairs(by[3]) do
      local it = I[iid]
      local pts, from = {}, nil
      for _, nid in ipairs(it and it[IK.npcDrops] or {}) do
        local n = N[nid]
        local r = n and n[NK.rank] or 0
        local list = n and type(n[NK.spawns]) == "table" and n[NK.spawns][areas[1]]
        if list and r ~= 1 and r ~= 2 and r ~= 3 then
          from = from or n[NK.name]
          for _, p in ipairs(list) do if p[1] and p[1] > 0 then pts[#pts + 1] = p end end
        end
      end
      local c = spot(pts)
      if c then return { id = iid, name = it[IK.name], area = areas[1], x = c[1], y = c[2], kind = "item", from = from } end
    end
    return nil
  end
  for _, id in ipairs(by[1] or {}) do
    local n = N[id]
    if n and friendly(n) then
      local a, list = inAreas(n[NK.spawns], areas)
      if a then return { id = id, name = n[NK.name], area = a, x = list[1][1], y = list[1][2], kind = "npc" } end
    end
  end
  for _, id in ipairs(by[2] or {}) do
    local o = O[id]
    if o then
      local a, list = inAreas(o[OK.spawns], areas)
      if a then return { id = id, name = o[OK.name], area = a, x = list[1][1], y = list[1][2], kind = "object" } end
    end
  end
end

-- Objective description and spot in the zone. Returns text, coords, ok (false = objectives outside the zone /
-- elite: leave the quest out).
local function objectives(q, area)
  local objs = q[K.objectives]
  local parts, points, elite, any = {}, {}, false, false
  local function addSpawns(spawns)
    local list = type(spawns) == "table" and spawns[area]
    if type(list) == "table" then for _, p in ipairs(list) do if p[1] and p[1] > 0 then points[#points + 1] = p end end end
  end
  if type(objs) == "table" then
    for _, o in ipairs(objs[1] or {}) do
      local n = N[o[1]]
      if n then
        any = true
        local r = n[NK.rank] or 0
        if r == 1 or r == 2 or r == 3 then elite = true end
        -- an objective with its own wording ("Peons awoken") isn't a kill
        parts[#parts + 1] = (type(o[2]) == "string" and o[2] ~= "") and (o[2] .. " (" .. n[NK.name] .. ")") or ("kill " .. n[NK.name])
        addSpawns(n[NK.spawns])
      end
    end
    for _, o in ipairs(objs[5] or {}) do -- kill credit: any of several creatures counts
      local ids, base, text = o[1], o[2], o[3]
      local n = N[base] or (type(ids) == "table" and N[ids[1]])
      if n then
        any = true
        parts[#parts + 1] = (type(text) == "string" and text ~= "") and text or ("kill " .. n[NK.name])
        for _, cid in ipairs(type(ids) == "table" and ids or {}) do if N[cid] then addSpawns(N[cid][NK.spawns]) end end
        addSpawns(n[NK.spawns])
      end
    end
    for _, o in ipairs(objs[2] or {}) do
      local ob = O[o[1]]
      if ob then any = true; parts[#parts + 1] = "use " .. ob[OK.name]; addSpawns(ob[OK.spawns]) end
    end
    for _, o in ipairs(objs[3] or {}) do
      local it = I[o[1]]
      if it then
        any = true
        local from = {}
        for _, nid in ipairs(it[IK.npcDrops] or {}) do
          local n = N[nid]
          if n and type(n[NK.spawns]) == "table" and n[NK.spawns][area] then
            local r = n[NK.rank] or 0
            if r ~= 1 and r ~= 2 and r ~= 3 then
              if #from < 2 then from[#from + 1] = n[NK.name] end
              addSpawns(n[NK.spawns])
            end
          end
        end
        for _, oid in ipairs(it[IK.objectDrops] or {}) do
          local ob = O[oid]
          if ob and type(ob[OK.spawns]) == "table" and ob[OK.spawns][area] then
            if #from < 2 then from[#from + 1] = ob[OK.name] end
            addSpawns(ob[OK.spawns])
          end
        end
        local nm = it[IK.name]
        if #from == 1 and from[1] == nm then from = {} end -- "Cactus Apple (Cactus Apple)"
        parts[#parts + 1] = "collect " .. nm .. (#from > 0 and (" (from " .. table.concat(from, ", ") .. ")") or "")
      end
    end
  end
  local te = q[K.triggerEnd]
  if type(te) == "table" and type(te[2]) == "table" and te[2][area] then
    any = true
    parts[#parts + 1] = "explore: " .. tostring(te[1])
    for _, p in ipairs(te[2][area]) do points[#points + 1] = p end
  end
  if not any then return nil, nil, true end -- delivery / talk quest: no objective step
  if elite then return nil, nil, false end
  if #points == 0 then return nil, nil, false end -- objectives somewhere else (dungeon, other zone)
  local text = table.concat(parts, "; ")
  text = text:sub(1, 1):upper() .. text:sub(2)
  return text, spot(points), true
end

local function dist(a, b)
  if not (a and b) or a.area ~= b.area then return 1e6 end
  return (a.x - b.x) ^ 2 + (a.y - b.y) ^ 2
end

-- order items with positions nearest-first from `from`
local function nearestOrder(items, from)
  local out, left, cur = {}, {}, from
  for _, it in ipairs(items) do left[#left + 1] = it end
  while #left > 0 do
    local bi, bd = 1, math.huge
    for i, it in ipairs(left) do local d = dist(cur, it.pos); if d < bd then bi, bd = i, d end end
    local it = table.remove(left, bi)
    out[#out + 1] = it
    cur = it.pos or cur
  end
  return out, cur
end

local done, taken = {}, {} -- quest IDs handed in / used by any earlier segment
local function prereqsMet(q)
  local p1 = q[K.preQuestSingle]
  if type(p1) == "table" and #p1 > 0 then
    local ok = false
    for _, id in ipairs(p1) do if done[id] then ok = true end end
    if not ok then return false end
  end
  for _, id in ipairs(q[K.preQuestGroup] or {}) do if not done[id] then return false end end
  for _, id in ipairs(q[K.exclusiveTo] or {}) do if taken[id] then return false end end
  return true
end

local function zoneNameOf(areaId)
  local names = { [1637] = "Orgrimmar", [1638] = "Thunder Bluff", [1497] = "Undercity" }
  return names[areaId]
end

local function fmtCoords(c) return string.format("{ %.1f, %.1f }", c[1], c[2]) end
local function esc(s) return (tostring(s):gsub("\\", "\\\\"):gsub('"', '\\"')) end

local function generate(seg)
  local areas = { seg.area }
  for _, a in ipairs(seg.extra or {}) do areas[#areas + 1] = a end
  for _, a in ipairs(plan.cities or {}) do areas[#areas + 1] = a end -- city hand-ins and deliveries
  -- candidates: quests filed under the segment's zone, or the sub-zones in `qareas` (starting areas file their
  -- quests under the sub-zone, e.g. Valley of Trials, while NPC spawns are recorded against the parent zone)
  local qzones = {}
  for _, z in ipairs(seg.qareas or { seg.area }) do qzones[z] = true end
  local cand, info = {}, {}
  local why = {}
  local function no(r) why[r] = (why[r] or 0) + 1 end
  for id, q in pairs(Q) do
    local lvl = q[K.questLevel] or q[K.requiredLevel] or 0
    if qzones[q[K.zoneOrSort] or 0] and lvl >= seg.qlo and lvl <= seg.qhi then
      if (q[K.requiredLevel] or 0) > seg.max + 1 then no("required level above the zone")
      elseif taken[id] then no("used earlier")
      elseif not raceOK(q, seg.races) then no("other faction/race")
      elseif q[K.requiredClasses] then no("class quest")
      elseif band(q[K.specialFlags] or 0, 1) ~= 0 then no("repeatable")
      elseif q[K.requiredSkill] then no("profession")
      else
        local s, f = endpoint(q, "start", areas), endpoint(q, "finish", areas)
        if not s then
          local sb = q[K.startedBy] or {}
          no((sb[3] and #sb[3] > 0) and "starts from an item" or "giver outside the zone/unfriendly")
        elseif not f then no("turn-in outside the zone")
        else
          local text, pos, ok = objectives(q, seg.area)
          if ok then
            cand[#cand + 1] = id
            info[id] = { start = s, finish = f, text = text, pos = pos and { area = seg.area, x = pos[1], y = pos[2] }, level = lvl }
          else
            no("elite or objectives outside the zone")
          end
        end
      end
    end
  end
  seg.why = why
  table.sort(cand, function(a, b) return info[a].level * 100000 + a < info[b].level * 100000 + b end)

  local steps, used, cur = {}, {}, nil
  local function addStep(s) steps[#steps + 1] = s end
  -- expected level as the zone goes on (the same straight line /fxp check uses), so a quest is only offered once
  -- the player can take it
  local expectSteps = 2.6 * #cand + 2
  local function levelNow() return seg.min + (seg.max - seg.min) * math.min(1, #steps / expectSteps) end
  for round = 1, 60 do
    local avail, waiting = {}, {}
    for _, id in ipairs(cand) do
      if not taken[id] and prereqsMet(Q[id]) then
        if (Q[id][K.requiredLevel] or 0) <= levelNow() + 1 then avail[#avail + 1] = id else waiting[#waiting + 1] = id end
      end
    end
    if #avail == 0 and #waiting > 0 then
      -- everything left needs more levels: grind to the lowest requirement, then carry on
      local need = math.huge
      for _, id in ipairs(waiting) do need = math.min(need, Q[id][K.requiredLevel] or 0) end
      if need <= seg.max + 1 then
        addStep({ level = need, coords = cur and { cur.x, cur.y } or nil, area = cur and cur.area or seg.area,
          text = string.format("Grind to %d for the next quests.", need) })
        while levelNow() + 1 < need do expectSteps = expectSteps * 0.9 end
        for _, id in ipairs(waiting) do if (Q[id][K.requiredLevel] or 0) <= need then avail[#avail + 1] = id end end
      end
    end
    if #avail == 0 then break end
    -- accept (log capped), grouped by giver
    local batch = {}
    for i = 1, math.min(#avail, LOG_CAP) do batch[#batch + 1] = avail[i]; taken[avail[i]] = true; used[#used + 1] = avail[i] end
    local byGiver, givers = {}, {}
    for _, id in ipairs(batch) do
      local s = info[id].start
      local key = s.kind .. s.id
      if not byGiver[key] then byGiver[key] = { ids = {}, ep = s, pos = { area = s.area, x = s.x, y = s.y } }; givers[#givers + 1] = byGiver[key] end
      table.insert(byGiver[key].ids, id)
    end
    local order
    order, cur = nearestOrder(givers, cur)
    for _, g in ipairs(order) do
      local text
      if g.ep.kind == "object" then text = g.ep.name .. "."
      elseif g.ep.kind == "item" then text = "Loot " .. g.ep.name .. " from " .. (g.ep.from or "the mobs here") .. " and right-click it to start the quest." end
      addStep({ accept = g.ids, npc = g.ep.kind == "npc" and g.ep.name or nil, coords = { g.ep.x, g.ep.y }, area = g.ep.area,
        radius = g.ep.kind == "item" and 80 or nil, text = text })
    end
    -- objectives
    local objs = {}
    for _, id in ipairs(batch) do if info[id].text then objs[#objs + 1] = { id = id, pos = info[id].pos } end end
    order, cur = nearestOrder(objs, cur)
    for _, o in ipairs(order) do
      addStep({ complete = { o.id }, coords = { o.pos.x, o.pos.y }, radius = 80, area = seg.area, text = info[o.id].text .. "." })
    end
    -- hand-ins, grouped by NPC
    local byTaker, takers = {}, {}
    for _, id in ipairs(batch) do
      local f = info[id].finish
      local key = f.kind .. f.id
      if not byTaker[key] then byTaker[key] = { ids = {}, ep = f, pos = { area = f.area, x = f.x, y = f.y } }; takers[#takers + 1] = byTaker[key] end
      table.insert(byTaker[key].ids, id)
    end
    order, cur = nearestOrder(takers, cur)
    for _, t in ipairs(order) do
      addStep({ turnin = t.ids, npc = t.ep.kind == "npc" and t.ep.name or nil, coords = { t.ep.x, t.ep.y }, area = t.ep.area,
        text = t.ep.kind == "object" and (t.ep.name .. ".") or nil })
      for _, id in ipairs(t.ids) do done[id] = true end
    end
  end
  return steps, used
end

local function questList(ids)
  if #ids == 1 then return tostring(ids[1]) end
  local s = {}
  for _, id in ipairs(ids) do s[#s + 1] = tostring(id) end
  return "{ " .. table.concat(s, ", ") .. " }"
end

local function emit(seg, steps, used)
  local L = {}
  local function w(s) L[#L + 1] = s end
  w("---------------------------------------------------------------------------")
  w(string.format('FXP:RegisterGuide("%s", {', esc(seg.name)))
  local races = ""
  if seg.races then
    local r = {}
    for _, x in ipairs(seg.races) do r[#r + 1] = '"' .. x .. '"' end
    races = ", races = { " .. table.concat(r, ", ") .. " }"
  end
  w(string.format('  faction = "%s"%s, minLevel = %d, maxLevel = %d, zone = "%s",', FACTION, races, seg.min, seg.max, esc(seg.zone)))
  if seg.next then w(string.format('  next = "%s",', esc(seg.next))) end
  w("  steps = {")
  local first = true
  for _, s in ipairs(steps) do
    local f = {}
    local function add(k, v) f[#f + 1] = k .. " = " .. v end
    if s.accept then add("accept", questList(s.accept)) end
    if s.complete then add("complete", questList(s.complete)) end
    if s.turnin then add("turnin", questList(s.turnin)) end
    if first and seg.hub then
      if seg.hub.fp then add("fp", '"' .. esc(seg.hub.fp) .. '"') end
      if seg.hub.bind then add("bind", '"' .. esc(seg.hub.bind) .. '"') end
    end
    if s.npc then add("npc", '"' .. esc(s.npc) .. '"') end
    if s.coords then add("coords", fmtCoords(s.coords)) end
    if s.level then add("level", tostring(s.level)) end
    if s.radius then add("radius", tostring(s.radius)) end
    if s.area ~= seg.area and zoneNameOf(s.area) then add("zone", '"' .. zoneNameOf(s.area) .. '"') end
    local text = s.text
    if first then
      local intro = {}
      if seg.intro then intro[#intro + 1] = seg.intro end
      if seg.hub and (seg.hub.fp or seg.hub.bind) then
        local hub = seg.hub.fp or seg.hub.bind
        intro[#intro + 1] = (seg.hub.fp and ("Get the " .. seg.hub.fp .. " flight path") or "") ..
          ((seg.hub.fp and seg.hub.bind) and " and " or "") .. (seg.hub.bind and ("set your Hearthstone in " .. seg.hub.bind) or "") .. "."
      end
      if text then intro[#intro + 1] = text end
      text = #intro > 0 and table.concat(intro, " ") or nil
    end
    if text then add("text", '"' .. esc(text) .. '"') end
    w("    { " .. table.concat(f, ", ") .. " },")
    first = false
  end
  local last = steps[#steps]
  w(string.format('    { level = %d, %sradius = 400, text = "Grind to %d if needed." },', seg.max,
    last and last.coords and last.area == seg.area and ("coords = " .. fmtCoords(last.coords) .. ", ") or "", seg.max))
  w(string.format('    { train = true, text = "Visit your class trainer for new skills.%s" },', seg.outro and (" " .. esc(seg.outro)) or ""))
  w("  },")
  w("})")
  w("")
  return table.concat(L, "\n"), #used
end

local files = {}
local report = {}
for _, seg in ipairs(plan.segments) do
  local steps, used = generate(seg)
  local text, n = emit(seg, steps, used)
  local qxp, need = 0, 0
  for _, id in ipairs(used) do qxp = qxp + (XP[id] or 0) end
  for l = seg.min, seg.max - 1 do need = need + (LEVEL_XP[l] or 0) end
  seg.coverage = need > 0 and math.floor(qxp * 100 / need + 0.5) or 0
  local key = seg.file
  files[key] = files[key] or {}
  table.insert(files[key], text)
  report[#report + 1] = string.format("%-30s %3d quests, %3d steps, quest XP covers %3d%% of the levels", seg.name, n, #steps + 2, seg.coverage)
  if VERBOSE then
    local r = {}
    for k, v in pairs(seg.why) do r[#r + 1] = k .. " " .. v end
    table.sort(r)
    report[#report + 1] = "      left out: " .. table.concat(r, ", ")
  end
end
local header = "-- %s: generated by Tools/dev/route_gen.lua from WoW Forever's quest data (QuestieDB) and %s.\n" ..
  "-- Hand edits are fine, but regenerating overwrites them: prefer changing the plan or the generator.\n" ..
  "local ADDON, ns = ...\nlocal FXP = ns.FXP\n\n"
for key, chunks in pairs(files) do
  local path = plan["file_" .. key]
  local fh = assert(io.open(arg_root .. "/" .. path, "w"))
  fh:write(header:format(path, plan_file), table.concat(chunks, "\n"))
  fh:close()
  io.write("wrote ", path, "\n")
end
for _, r in ipairs(report) do io.write(r, "\n") end
