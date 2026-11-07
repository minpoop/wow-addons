local F = ForeverXP
local W = F:Register("Waypoints", {})
function W:Set(waypoint)
    if waypoint ~= nil and not F.modules.StepValidator:Waypoint(waypoint) then return nil, "invalid waypoint" end
    self.current = waypoint and F.modules.SavedVariables.Copy(waypoint) or nil
    F.modules.Events:Emit("FXP_CHANGED")
    return true
end
function W:Text()
    if not self.current or not F.settings.waypoints then return "No waypoint" end
    local w = self.current
    local note=w.verification=="reference-reviewed" and "Reference coordinates · confirm in game" or "Coordinate guidance · direction unavailable"
    return string.format("%s  ·  %.1f, %.1f\n%s", tostring(w.zone), w.x * 100, w.y * 100,note)
end
