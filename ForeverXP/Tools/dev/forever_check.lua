-- Offline route check against WoW Forever's real quest data (Questie's QuestieDB repository).
-- Runs the addon's own /fxp check (FXP:CheckRoute) with a Questie built from the data files, so no game is needed.
--
-- Run from the addon folder (needs a QuestieDB checkout: git clone https://github.com/Questie/QuestieDB):
--   lua -e "arg_root='.'; qdb_root='/path/to/QuestieDB'" Tools/dev/forever_check.lua
--   (or with Tools/dev/lua_run.py: write those two globals and dofile this script from a wrapper)
-- Prints the same text as /fxp export's route check section. Corrections from src/corrections are not
-- applied (they're runtime code), so a few quests the live addon fixes up may differ.
assert(arg_root and qdb_root, "set arg_root (addon folder) and qdb_root (QuestieDB checkout)")

local function read(path)
  local f = assert(io.open(path, "r"), "can't open " .. path)
  local t = f:read("*a"); f:close(); return t
end

-- Data files are "X.fooData = [[return {...}]]" strings inside a module file: run the module with stubs,
-- then load the strings.
local modules = {}
QuestieLoader = { ImportModule = function(_, name) modules[name] = modules[name] or { private = {} }; return modules[name] end }
local function run(path) assert(load(read(path), "@" .. path))() end
run(qdb_root .. "/data/Forever/foreverQuestDB.lua")
run(qdb_root .. "/data/Forever/foreverNpcDB.lua")
run(qdb_root .. "/data/Forever/foreverObjectDB.lua")
run(qdb_root .. "/data/Forever/foreverItemDB.lua")
local zonePath = qdb_root .. "/support/Forever/Zones/areaIdToUiMapId.lua"
if not io.open(zonePath, "r") then zonePath = qdb_root .. "/support/Zones/areaIdToUiMapId.lua" end
run(zonePath)
local QDB, ZDB = modules.QuestieDB, modules.ZoneDB
local function unpackData(s) return type(s) == "string" and assert(load(s))() or s end
local quests, npcs = unpackData(QDB.questData), unpackData(QDB.npcData)
local objects, items = unpackData(QDB.objectData), unpackData(QDB.itemData)
local area = unpackData(ZDB.private.areaIdToUiMapId)
for k, v in pairs(unpackData(ZDB.private.areaIdToUiMapIdOverride) or {}) do area[k] = v end
local count = 0
for _ in pairs(quests) do count = count + 1 end
io.write(("WoW Forever data: %d quests\n"):format(count))

-- Load the addon in the harness's stubbed WoW (everything before the harness's own tests).
local h = read(arg_root .. "/Tools/dev/harness.lua")
local cut = h:find("\nlocal fails = 0", 1, true)
local prefix = h:sub(1, cut) .. "\nreturn ns\n"
local ns = assert(load(prefix, "@harness-prefix"))()
local FXP = ns.FXP
FXP.db = { step = 1, trained = {}, catchUp = true, skipGroup = false }
UnitFactionGroup = function() return "Alliance" end
bit = bit or { band = function(a, b) return math.floor(a) & math.floor(b) end } -- race masks exceed 32 bits in Forever
-- run timers straight away so the name index and the check finish synchronously
local queue = {}
C_Timer.After = function(_, fn) queue[#queue + 1] = fn end
C_Timer.NewTicker = function(_, fn)
  local t = { cancelled = false }
  t.Cancel = function() t.cancelled = true end
  queue[#queue + 1] = function() while not t.cancelled do fn() end end
  return t
end
local function drain() local n = 0 while #queue > 0 and n < 100000 do n = n + 1; table.remove(queue, 1)() end end

-- Questie, backed by the data files
local function getter(data, keys)
  return function(id, key)
    local row = data[id]
    return row and row[keys[key]]
  end
end
local QZ = ns.Questie
QZ.DB = {
  QueryQuestSingle = getter(quests, QDB.questKeys), QueryNPCSingle = getter(npcs, QDB.npcKeys),
  QueryObjectSingle = getter(objects, QDB.objectKeys), QueryItemSingle = getter(items, QDB.itemKeys),
  QuestPointers = (function() local p = {} for id in pairs(quests) do p[id] = true end return p end)(),
}
QZ.ZoneDB = { GetUiMapIdByAreaId = function(_, a) return area[a] end }
QZ.ready = true
QZ:BuildNameIndex()
drain()
assert(QZ.indexDone, "name index didn't finish")

local said = {}
FXP.Print = function(fmt, ...) said[#said + 1] = string.format(fmt, ...) end
ForeverXPDB = {}
FXP:CheckRoute()
drain()
for _, l in ipairs(said) do io.write("# ", l, "\n") end
local rc = ForeverXPDB.routeCheck
assert(rc, "route check didn't run")
for _, f in ipairs(rc.findings) do
  io.write(string.format("- %s #%s%s: %s%s\n", f.guide or "?", f.step or "?", f.src and (" (file step " .. f.src .. ")") or "",
    f.quest and (f.quest .. " - ") or "", f.issue or ""))
end
io.write(string.format("%d findings\n", #rc.findings))
FOREVER = { quests = quests, npcs = npcs, keys = QDB.questKeys, npcKeys = QDB.npcKeys, ns = ns, QZ = QZ }
return FOREVER
