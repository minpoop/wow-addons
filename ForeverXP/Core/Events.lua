local F = ForeverXP
local E = F:Register("Events", { handlers = {}, registered = {} })
function E:On(event, key, fn)
    assert(type(fn) == "function", "event handler required")
    self.handlers[event] = self.handlers[event] or {}
    self.handlers[event][key] = fn -- repeated initialization replaces, never leaks
    if self.frame and not string.match(event, "^FXP_") and not self.registered[event] then
        local ok = pcall(self.frame.RegisterEvent, self.frame, event)
        self.registered[event] = ok or nil
    end
end
function E:Off(event, key)
    local handlers = self.handlers[event]
    if not handlers then return end
    handlers[key] = nil
    if not next(handlers) then
        self.handlers[event] = nil
        if self.frame and self.registered[event] then pcall(self.frame.UnregisterEvent, self.frame, event) end
        self.registered[event] = nil
    end
end
function E:Emit(event, ...)
    for key, fn in pairs(self.handlers[event] or {}) do
        local ok, err = pcall(fn, ...)
        if not ok then F:Log(event .. "/" .. key .. ": " .. tostring(err)) end
    end
end
function E:Start()
    if self.frame then return true end
    local frame, err = F.modules.Compatibility:Call("CreateFrame", "Frame")
    if not frame then return nil, err end
    local ok = pcall(frame.SetScript, frame, "OnEvent", function(_, event, ...) E:Emit(event, ...) end)
    if not ok then return nil, "Event callback API unsupported" end
    self.frame = frame
    for event in pairs(self.handlers) do
        if not string.match(event, "^FXP_") then
            local registered = pcall(frame.RegisterEvent, frame, event)
            self.registered[event] = registered or nil
        end
    end
    return true
end
