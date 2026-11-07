local F = ForeverXP
local D = F:Register("Detours", {})
local function mainWaypoint()
    local step = F.modules.GuideEngine:Current()
    return step and step.waypoint or nil
end
function D:Suggest(resource, zone, skill)
    if F.settings.integration == "disabled" or self.active then return {} end
    local routes = F.modules.GatheringRoutes:Find(resource, zone, skill)
    local limit = ({minimal=1,balanced=3})[F.settings.integration] or #routes
    while #routes > limit do table.remove(routes) end
    return routes
end
function D:Start(id, consent)
    if consent ~= true then return nil, "Explicit consent is required for a profession detour." end
    if F.settings.integration == "disabled" then return nil, "Profession integration is disabled." end
    if self.active then return nil, "Finish or cancel the active detour first." end
    local route = F.modules.GatheringRoutes.routes[id]
    if not route then return nil, "unknown verified route" end
    local guide = F.modules.GuideEngine
    self.active = { route = F.modules.SavedVariables.Copy(route), index = 1,
        guide = guide.guide and guide.guide.id, step = guide:Current() and guide:Current().id,
        previous = F.modules.SavedVariables.Copy(F.modules.Waypoints.current) }
    F.modules.Waypoints:Set(self.active.route.points[1])
    return true
end
function D:Next()
    if not self.active then return nil, "no active detour" end
    self.active.index = self.active.index + 1
    local point = self.active.route.points[self.active.index]
    if not point then return self:Cancel() end
    F.modules.Waypoints:Set(point)
    return true
end
function D:Cancel()
    if not self.active then return true end
    local previous = self.active.previous
    local hadGuide = self.active.guide ~= nil
    self.active = nil
    local guide = F.modules.GuideEngine
    local destination = mainWaypoint()
    if not hadGuide and not guide.guide then destination = previous end
    F.modules.Waypoints:Set(destination)
    return true
end
function D:GuideChanged()
    if not self.active then F.modules.Waypoints:Set(mainWaypoint()); return end
    local guide = F.modules.GuideEngine
    local id = guide.guide and guide.guide.id
    local step = guide:Current() and guide:Current().id
    -- Explicit main-guide navigation cancels the detour instead of restoring stale state.
    if id ~= self.active.guide or step ~= self.active.step then self:Cancel() end
end
