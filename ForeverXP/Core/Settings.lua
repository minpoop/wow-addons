local F = ForeverXP
local S = F:Register("Settings", {})
S.defaults = { autoAdvance = true, arrow = true, sound = false, integration = "disabled", theme = "fog",
    scale = 1, opacity = 0.95, compact = false, debug = false, waypoints = true,
    recovery = "suggest", navigationInterval = 0.2 }
function S:Load(raw)
    local settings = {}
    for k, default in pairs(self.defaults) do
        local value = raw[k]
        if type(value) == type(default) and (type(value) ~= "number" or (value == value and math.abs(value) < math.huge)) then
            settings[k] = value
        else settings[k] = default end
    end
    settings.scale = math.max(0.6, math.min(1.8, settings.scale))
    settings.opacity = math.max(0.25, math.min(1, settings.opacity))
    settings.navigationInterval = math.max(0.1, math.min(2, settings.navigationInterval))
    if not ({ disabled=true, minimal=true, balanced=true, focused=true })[settings.integration] then settings.integration = "disabled" end
    if settings.recovery ~= "suggest" and settings.recovery ~= "disabled" then settings.recovery = "suggest" end
    if not ({fog=true,contrast=true,warcraft=true,warhammer=true})[settings.theme] then settings.theme = "fog" end
    return settings
end
function S:Set(key, value)
    if type(value) ~= type(self.defaults[key]) then return nil, "invalid setting" end
    local candidate = F.modules.SavedVariables.Copy(F.settings)
    candidate[key] = value
    F.settings = self:Load(candidate); F.db.settings = F.settings
    F.modules.Events:Emit("FXP_CHANGED")
    return true
end
