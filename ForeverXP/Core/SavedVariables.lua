local F = ForeverXP
local D = F:Register("SavedVariables", { schema = 1 })
local function copy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}; seen[value] = result
    for k, v in pairs(value) do result[copy(k, seen)] = copy(v, seen) end
    return result
end
D.Copy = copy
local function fresh() return { schema = 1, settings = {}, characters = {} } end
function D:Open(raw)
    self.readOnly, self.warning = false, nil
    if raw == nil then return fresh() end
    -- Preserve the original wholesale; never guess how to migrate unknown schemas.
    if type(raw) ~= "table" or (raw.schema ~= nil and raw.schema ~= 0 and raw.schema ~= 1) then
        self.readOnly = true; self.warning = "Unknown or corrupt save schema; original retained, session-only mode."
        return fresh()
    end
    local db = copy(raw)
    if db.schema == nil or db.schema == 0 then
        db.migrationBackup = copy(raw)
        db.schema = 1
    end
    if type(db.settings) ~= "table" or type(db.characters) ~= "table" then
        self.readOnly = true; self.warning = "Malformed save tables; original retained, session-only mode."
        return fresh()
    end
    return db
end
function D:Character(db, identity)
    if not identity then return { guides = {}, professions = {}, windows = {} }, false end
    local existing = db.characters[identity]
    if existing ~= nil and (type(existing) ~= "table" or type(existing.guides) ~= "table"
       or type(existing.professions) ~= "table" or type(existing.windows) ~= "table") then
        return { guides = {}, professions = {}, windows = {} }, false
    end
    if not existing then
        existing = { guides = {}, professions = {}, windows = {} }
        db.characters[identity] = existing
    end
    return existing, not self.readOnly
end
