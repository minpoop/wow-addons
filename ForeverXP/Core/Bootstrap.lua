local F = ForeverXP
local E, C, D, U = F.modules.Events, F.modules.Compatibility, F.modules.SavedVariables, F.modules.MainWindow
function F:AttachCharacter()
    local identity = C:Identity()
    if not identity or identity == self.identity then return end
    -- Do not silently replace an anonymous session which may contain user edits.
    if self.character and (next(self.character.guides) or next(self.character.professions)) then
        self:Print("Identity became available; session progress retained. Reload after exporting/reviewing progress to attach a character.")
        return
    end
    self.identity = identity
    self.character, self.persistent = D:Character(self.db, identity)
    if self.character.selectedGuide then
        local ok, err = self.modules.GuideEngine:Select(self.character.selectedGuide,self.character)
        if not ok then self:Log(err) end
    end
    if self.character.selectedProfession then
        local ok, err = self.modules.ProfessionController:Select(self.character.selectedProfession)
        if not ok then self:Log(err) end
    end
    if U.frame then U:RestorePosition() end
end
function F:Initialize()
    if self.initialized then return end
    self.db = D:Open(ForeverXPDB)
    self.settings = self.modules.Settings:Load(self.db.settings)
    self.db.settings = self.settings
    if not D.readOnly then ForeverXPDB = self.db end
    self.character, self.persistent = D:Character(self.db,nil)
    self:AttachCharacter()
    self.initialized = true
    self.modules.ForeverAdapter:Start()
    if D.warning then self:Print(D.warning) end
    if not self.persistent then self:Print("Progress is session-only until a valid character identity and save are available.") end
    local ok, err = U:Build()
    if not ok then self:Print(err) end
end
function F:Refresh()
    if not self.initialized then return end
    self:AttachCharacter()
    local snapshot = C:Read("snapshot")
    if type(snapshot) == "table" then
        self.modules.LiveJournal:Sync(snapshot)
        self.modules.GuideEngine:Update(snapshot)
        self.snapshot=snapshot
    else self.snapshot=nil end
    self.modules.ProfessionController:Refresh()
    U:Render()
end
function F:Command(message)
    if not self.initialized then self:Print("Waiting for addon-loaded event; saved data has not been read."); return end
    local cmd, arg = string.match(message or "", "^%s*(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd)
    if cmd == "" then U:Toggle()
    elseif cmd == "guide" or cmd == "professions" or cmd == "settings" then U:Show(cmd)
    elseif cmd == "journal" then
        local ok,err=self.modules.LiveJournal:Open()
        if ok then U:Show("guide") else self:Print(err) end
    elseif cmd == "elwynn" then
        local player=C:Character()
        if player.faction and player.faction~="Alliance" then self:Print("The Elwynn route is intended for Alliance characters.")
        else
            local ok,err=self.modules.GuideEngine:Select("elwynn-forest-shared",self.character)
            if ok then
                self:Print("Elwynn reference route selected: shared quests for all classes; Forever route validation is still in progress.")
                self:Refresh(); U:Show("guide")
            else self:Print(err) end
        end
    elseif cmd == "focus" then
        local ok,err=self.modules.LiveJournal:Focus(tonumber(arg))
        if ok then U:Show("guide") else self:Print(err) end
    elseif cmd == "quests" then
        local data=self.character.liveJournal
        if type(data)~="table" or not self.modules.Validation.Array(data.order) or type(data.quests)~="table" then self:Print("Open /fxp journal to collect your quests.")
        else
            for _,id in ipairs(data.order) do
                local record=data.quests[id]
                if type(record)=="table" and type(record.title)=="string" then self:Print(tostring(id).." · "..record.title) end
            end
            self:Print("Use /fxp focus QUEST_ID to choose a quest without confirming other steps.")
        end
    elseif cmd == "tracking" then
        local a=self.modules.ForeverAdapter
        local snapshot=self.modules.Compatibility:Read("snapshot")
        self:Print("Tracking: " .. (a.enabled and "source-inspected adapter" or "unavailable") .. "; live gameplay validation pending.")
        if snapshot then
            self:Print("Readable active quests: "..#snapshot.active..". Use /fxp journal for your current quests.")
            local p=snapshot.character or {}
            self:Print("Character: "..tostring(p.faction).." / "..tostring(p.race).." / "..tostring(p.class).."; level "..tostring(snapshot.level).."; zone "..tostring(p.zone))
        else self:Print(C.failures.snapshot or a.error or "Quest data currently unavailable.") end
    elseif cmd == "auto" then self.modules.Settings:Set("autoAdvance",not self.settings.autoAdvance); U:Render()
    elseif cmd == "compact" then self.modules.Settings:Set("compact",not self.settings.compact); U:Render()
    elseif cmd == "debug" then self.modules.Settings:Set("debug",not self.settings.debug); self:Print("Debug: " .. tostring(self.settings.debug))
    elseif cmd == "theme" then
        if not self.modules.Themes.palettes[arg] then self:Print("Use /fxp theme fog or /fxp theme contrast.")
        else self.modules.Settings:Set("theme",arg); U:Render() end
    elseif cmd == "scale" or cmd == "opacity" then
        local value = tonumber(arg)
        if not value or value ~= value or math.abs(value) == math.huge then self:Print("Supply a finite number.")
        else self.modules.Settings:Set(cmd,value); U:Render() end
    elseif cmd == "next" then self.modules.GuideEngine:Advance(true)
    elseif cmd == "back" then self.modules.GuideEngine:Back()
    elseif cmd == "skip" then local _, err = self.modules.GuideEngine:Skip(); if err then self:Print(err) end
    elseif cmd == "select" then
        local _, err = self.modules.GuideEngine:Select(arg,self.character); if err then self:Print(err) end
    elseif cmd == "profession" then
        local _, err = self.modules.ProfessionController:Select(arg); if err then self:Print(err) else U:Show("professions") end
    elseif cmd == "target" or cmd == "mode" or cmd == "estimate" then
        local value = cmd == "target" and tonumber(arg) or arg
        local _, err = self.modules.ProfessionController:Change(cmd,value); if err then self:Print(err) end
    elseif cmd == "price" then
        local item, value = arg:match("^(%S+)%s+(%S+)$")
        local _, err = self.modules.ProfessionController:Price(tonumber(item) or item,tonumber(value))
        if err then self:Print(err) end
    elseif cmd == "materials" then
        local controller = self.modules.ProfessionController
        if not controller.plan then self:Print("No profession plan available.")
        else
            if controller.stale then self:Print("Previous plan; current data unavailable.") end
            local materials, ids = controller.plan.materials, {}
            for id,count in pairs(materials.raw) do if count > 0 then ids[#ids+1] = id end end
            table.sort(ids,function(a,b) return tostring(a)<tostring(b) end)
            for _,id in ipairs(ids) do self:Print(string.format("%s: need %d, owned used %d, missing %d",tostring(id),materials.raw[id],materials.used[id] or 0,materials.missing[id] or 0)) end
        end
    elseif cmd == "integration" then
        if not ({disabled=true,minimal=true,balanced=true,focused=true})[arg] then self:Print("Use disabled, minimal, balanced or focused.")
        else
            self.modules.Settings:Set("integration",arg)
            if arg == "disabled" then self.modules.Detours:Cancel() end
        end
    elseif cmd == "detour" then
        local id = arg:match("^start%s+(%S+)%s+confirm$")
        local ok, err
        if id then ok, err = self.modules.Detours:Start(id,true)
        elseif arg == "next" then ok, err = self.modules.Detours:Next()
        elseif arg == "cancel" then ok, err = self.modules.Detours:Cancel()
        else err = "Use /fxp detour start ROUTE confirm, next or cancel." end
        if err then self:Print(err) end
    elseif cmd == "record" then
        local _, err = self.modules.GatheringRoutes:Record(self.character,arg); if err then self:Print(err) end
    elseif cmd == "diagnostics" then
        local b = C:Build()
        self:Print("Target interface=" .. C.profile.interface .. " from working Questie_Forever.toc; runtime APIs remain unverified.")
        self:Print("Observed version=" .. tostring(b.version) .. " build=" .. tostring(b.build) .. " interface=" .. tostring(b.interface) .. "; profile verified=" .. tostring(b.verified))
        for _, name in ipairs({"CreateFrame","GetBuildInfo","UnitGUID","GetQuestLogTitle","C_QuestLog","GetTradeSkillInfo","C_TradeSkillUI","GetPlayerMapPosition","C_Map"}) do
            self:Print(name .. ": " .. type(_G[name]) .. " (presence only)")
        end
    elseif cmd == "reset" then
        if arg ~= "confirm" or not self.pendingReset then
            self.pendingReset = true; self:Print("Reset this character's addon progress? Type /fxp reset confirm. Settings and other characters are retained.")
        else
            local backup = D.Copy(self.character)
            self.character.guides, self.character.professions, self.character.selectedGuide, self.character.selectedProfession = {}, {}, nil, nil
            self.character.resetBackup = backup
            -- Bound reset backup nesting to one snapshot.
            backup.resetBackup = nil
            self.modules.GuideEngine.guide, self.modules.GuideEngine.state = nil, nil
            local controller = self.modules.ProfessionController
            controller.catalog, controller.state, controller.plan, controller.error = nil, nil, nil, nil
            self.modules.Detours.active = nil
            self.character.liveJournal=nil
            self.modules.Waypoints:Set(nil); self.pendingReset = nil
            self:Print("Character progress reset; one pre-reset backup retained."); U:Render()
        end
    else self:Print("/fxp [elwynn|journal|quests|focus QUEST_ID|tracking|guide|select ID|professions|profession ID|target N|mode Farm/Buy/Hybrid|estimate expected/conservative/guaranteed|price ITEM N|materials|integration MODE|detour|record ID|settings|next|back|skip|auto|compact|scale N|opacity N|debug|diagnostics|reset]") end
end
-- SlashCmdList and event semantics are compatibility candidates, tested with mocks.
if type(SlashCmdList) == "table" and not SlashCmdList.FOREVERXP then
    SLASH_FOREVERXP1, SLASH_FOREVERXP2 = "/fxp", "/foreverxp"
    SlashCmdList.FOREVERXP = function(message) F:Command(message) end
end
E:On("ADDON_LOADED", "bootstrap", function(name) if name == "ForeverXP" then F:Initialize() end end)
E:On("PLAYER_LOGIN", "refresh", function() F:Refresh() end)
E:On("PLAYER_ENTERING_WORLD", "refresh", function() F:Refresh() end)
-- Verified providers should register their client-specific event names themselves.
E:On("FXP_STATE_CHANGED", "refresh", function() F:Refresh() end)
E:On("FXP_GUIDE_CHANGED", "waypoint", function()
    F.modules.Detours:GuideChanged()
end)
E:On("FXP_CHANGED", "render", function() U:Render() end)
local ok, err = E:Start()
if not ok then F:Print("Event bridge unavailable: " .. tostring(err)) end
