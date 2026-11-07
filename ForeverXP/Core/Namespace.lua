-- One public namespace; modules never depend on addon varargs or a client generation.
ForeverXP = { version = "0.5.1-dev", modules = {} }
local F = ForeverXP
function F:Register(name, module)
    assert(type(name) == "string" and type(module) == "table", "invalid module")
    assert(not self.modules[name], "duplicate module: " .. name)
    self.modules[name] = module
    return module
end
function F:Log(message)
    if self.settings and self.settings.debug then self:Print(message) end
end
function F:Print(message)
    local text = "ForeverXP: " .. tostring(message)
    if DEFAULT_CHAT_FRAME and type(DEFAULT_CHAT_FRAME.AddMessage) == "function" then
        pcall(DEFAULT_CHAT_FRAME.AddMessage, DEFAULT_CHAT_FRAME, text)
    elseif type(print) == "function" then print(text) end
end
