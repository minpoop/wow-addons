local F = ForeverXP
local C = F:Register("Compatibility", { providers = {}, failures = {} })
-- Capability presence is not proof of client compatibility. Providers require
-- an explicit verified profile; no quest/map/profession API family is guessed.
C.profile = { verified = false, reportedVersion = "1.60.70790", interface = 16001,
    interfaceSource = "User-supplied working Questie_Forever.toc" }
function C:Call(name, ...)
    local fn = _G[name]
    if type(fn) ~= "function" then return nil, "unsupported: " .. name end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then self.failures[name] = tostring(a); return nil, "failed: " .. name end
    return a, b, c, d
end
function C:Build()
    local version, build, date, interface = self:Call("GetBuildInfo")
    return { version = version, build = build, date = date, interface = interface,
             verified = self.profile.verified }
end
function C:Identity()
    local guid = self:Call("UnitGUID", "player")
    if type(guid) == "string" and guid ~= "" then return guid end
    local name = self:Call("UnitName", "player")
    local realm = self:Call("GetRealmName")
    if type(name) == "string" and name ~= "" and type(realm) == "string" and realm ~= "" then
        return realm .. ":" .. name
    end
    return nil, "Character identity unavailable; progress is session-only."
end
function C:RegisterProvider(name, fn)
    assert(self.profile.verified, "verify client profile before registering providers")
    assert(type(fn) == "function", "provider must be a function")
    self.providers[name] = fn
end
function C:Read(name, ...)
    if not self.profile.verified then return nil, "client profile unverified" end
    local fn = self.providers[name]
    if not fn then return nil, "unsupported capability: " .. name end
    local ok, value = pcall(fn, ...)
    if not ok then self.failures[name] = tostring(value); return nil, "provider failed: " .. name end
    return value
end
function C:Character()
    -- These generic probes are diagnostic candidates, not certified adapters.
    local _, faction = self:Call("UnitFactionGroup", "player")
    local _, race = self:Call("UnitRace", "player")
    local _, class = self:Call("UnitClass", "player")
    return { faction = faction, race = race, class = class,
             level = self:Call("UnitLevel", "player"), zone = self:Call("GetZoneText") }
end
