local F = ForeverXP
local R = F:Register("GatheringRoutes", { routes = {} })
local V = F.modules.Validation
function R:Validate(route, production)
    if type(route) ~= "table" or not V.DataOnly(route) then return nil, "route must be finite, acyclic data" end
    if not V.String(route.id) or not V.String(route.title) or not V.Key(route.zone) or not V.Key(route.resource)
       or not V.String(route.description) or not V.String(route.difficulty) then return nil, "route metadata required" end
    if not V.Integer(route.minSkill) or not V.Integer(route.maxSkill) or route.minSkill > route.maxSkill then return nil, "invalid route skill range" end
    if production and not V.Verified(route) then return nil, "live verification and source required" end
    if not V.Array(route.points, true) or #route.points > 512 then return nil, "route needs 1–512 ordered points" end
    for _, point in ipairs(route.points) do
        if not F.modules.StepValidator:Waypoint(point) or point.zone ~= route.zone then return nil, "invalid or mismatched route coordinates" end
    end
    return true
end
function R:RegisterRoute(route)
    local ok, err = self:Validate(route, true)
    if not ok then return nil, err end
    if self.routes[route.id] then return nil, "duplicate route" end
    self.routes[route.id] = F.modules.SavedVariables.Copy(route)
    return true
end
function R:ImportDraft(character, route)
    local ok, err = self:Validate(route, false)
    if not ok then return nil, err end
    if character.recordedRoutes ~= nil and type(character.recordedRoutes) ~= "table" then return nil, "corrupt recordings retained" end
    local routes = character.recordedRoutes or {}
    if routes[route.id] then return nil, "draft already exists" end
    local count = 0; for _ in pairs(routes) do count = count + 1 end
    if count >= 100 then return nil, "recording limit reached" end
    local draft = F.modules.SavedVariables.Copy(route)
    -- Imported/recorded observations cannot certify spawn correctness or server support.
    draft.verification = "unverified-observation"
    routes[draft.id], character.recordedRoutes = draft, routes
    return true
end
function R:Record(character, id)
    local routes = character.recordedRoutes
    local route = type(routes) == "table" and routes[id]
    if not route then return nil, "import a route draft before recording" end
    local valid, err = self:Validate(route, false)
    if not valid then return nil, err end
    if route.verification == "live-verified" then return nil, "record into an unverified draft only" end
    local position = F.modules.Compatibility:Read("position")
    if not F.modules.StepValidator:Waypoint(position) then return nil, "verified position provider unavailable" end
    if position.zone ~= route.zone then return nil, "recording zone differs from draft" end
    if #route.points >= 512 then return nil, "waypoint limit reached" end
    local last = route.points[#route.points]
    if last.x == position.x and last.y == position.y then return nil, "duplicate observation" end
    route.points[#route.points+1] = { zone = position.zone, x = position.x, y = position.y }
    return true
end
function R:Find(resource, zone, skill)
    local found = {}
    if not V.Integer(skill) then return found end
    for _, route in pairs(self.routes) do
        if route.resource == resource and route.zone == zone and skill >= route.minSkill and skill <= route.maxSkill then found[#found+1] = route end
    end
    table.sort(found, function(a,b) return a.id < b.id end)
    return found -- same-zone does not claim measured proximity or travel time
end
