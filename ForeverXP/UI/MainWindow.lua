local F = ForeverXP
local U = F:Register("MainWindow", { tab = "guide" })
local T = F.modules.Themes
local function size(frame, width, height) frame:SetWidth(width); frame:SetHeight(height) end
local function text(parent, points, width)
    local label = parent:CreateFontString(nil, "OVERLAY")
    if GameFontNormal then label:SetFontObject(GameFontNormal)
    else label:SetFont("Fonts\\FRIZQT__.TTF", 12) end
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", points[1], points[2])
    label:SetWidth(width); label:SetJustifyH("LEFT")
    T:Text(label,T:Get().text)
    return label
end
local function button(parent, title, x, y, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    size(b, width, 25); b:SetPoint("TOPLEFT", parent, "TOPLEFT", x+156, y)
    local bg = b:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(b)
    T:Texture(bg,T:Get().button)
    local label = text(b, {8,-6}, width-12); label:SetText(title)
    b:SetScript("OnClick", onClick)
    b.background,b.label = bg,label
    U.buttons = U.buttons or {}; U.buttons[#U.buttons+1] = b
    b:SetScript("OnEnter", function() T:Texture(bg,T:Get().hover); T:Text(label,T:Get().accent) end)
    b:SetScript("OnLeave", function() U:PaintButton(b) end)
    return b, label
end
function U:PaintButton(b)
    local selected = b.tab == self.tab or (b.mode and F.modules.ProfessionController.state and b.mode == F.modules.ProfessionController.state.mode)
    T:Texture(b.background,selected and T:Get().selected or T:Get().button)
    T:Text(b.label,selected and T:Get().accent or T:Get().text)
end
function U:Paint()
    local theme = T:Get()
    T:Texture(self.background,theme.panel)
    T:Texture(self.edge,theme.border)
    T:Texture(self.portraitBorder,theme.border)
    T:Text(self.portraitName,theme.accent)
    for _, band in ipairs(self.fog) do T:Texture(band,theme.fog) end
    T:Text(self.title,theme.muted); T:Text(self.companion,theme.muted); T:Text(self.heading,theme.accent)
    T:Text(self.body,theme.text); T:Text(self.footer,theme.muted)
    T:Texture(self.progressTrack,theme.track); T:Texture(self.progressFill,theme.progress)
    for _, b in ipairs(self.buttons) do self:PaintButton(b) end
end
function U:SavePosition()
    if not self.frame or not F.character then return end
    local point, _, relativePoint, x, y = self.frame:GetPoint(1)
    F.character.windows.main = { point = point, relativePoint = relativePoint, x = x, y = y }
end
function U:RestorePosition()
    local w = F.character and F.character.windows.main
    local points = {TOP=true,TOPLEFT=true,TOPRIGHT=true,CENTER=true,LEFT=true,RIGHT=true,BOTTOM=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    self.frame:ClearAllPoints()
    if type(w) == "table" and points[w.point] and points[w.relativePoint]
       and type(w.x) == "number" and math.abs(w.x) < 10000 and type(w.y) == "number" and math.abs(w.y) < 10000 then
        self.frame:SetPoint(w.point, UIParent, w.relativePoint, w.x, w.y)
    else self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
end
function U:Build()
    if self.frame then return true end
    if type(CreateFrame) ~= "function" or not UIParent then return nil, "UI frame API unavailable" end
    local partial
    local ok, err = pcall(function()
        self.buttons = {}
        local frame = CreateFrame("Frame", nil, UIParent); partial = frame
        size(frame, 576, 380); frame:SetFrameStrata("MEDIUM")
        frame:SetMovable(true); frame:EnableMouse(true); frame:SetClampedToScreen(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); U:SavePosition() end)
        local background = frame:CreateTexture(nil, "BACKGROUND"); background:SetAllPoints(frame)
        self.background = background
        self.edge = frame:CreateTexture(nil,"ARTWORK"); self.edge:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0); size(self.edge,576,2)
        self.portraitBorder = frame:CreateTexture(nil,"BACKGROUND")
        self.portraitBorder:SetPoint("TOPLEFT",frame,"TOPLEFT",16,-90); size(self.portraitBorder,132,132)
        self.portrait = frame:CreateTexture(nil,"ARTWORK")
        self.portrait:SetPoint("TOPLEFT",frame,"TOPLEFT",18,-92); size(self.portrait,128,128)
        self.portrait:SetTexture("Interface\\AddOns\\ForeverXP\\Assets\\JamesSunderland.tga")
        self.portraitName = text(frame,{18,-226},132); self.portraitName:SetText("James Sunderland")
        self.fog = {}
        for i=1,6 do
            local band = frame:CreateTexture(nil,"BORDER")
            band:SetPoint("TOPLEFT",frame,"TOPLEFT",2,-24-i*29); size(band,572,12+i*2)
            self.fog[#self.fog+1] = band
        end
        self.title = text(frame, {18,-16}, 500); self.title:SetText("FOREVER XP  /  FIELD JOURNAL")
        self.companion = text(frame,{18,-32},520)
        button(frame, "×", 380,-8,27,function() frame:Hide() end)
        local captions = {guide="ROUTE",professions="SUPPLIES",settings="OPTIONS"}
        for i, tab in ipairs({"guide","professions","settings"}) do
            local selected = tab
            local b = button(frame, captions[tab], 18+(i-1)*128,-48,120,function() U:Show(selected) end)
            b.tab = tab
        end
        self.heading = text(frame,{174,-92},384)
        self.body = text(frame,{174,-120},384)
        self.footer = text(frame,{174,-282},384)
        self.progressTrack = frame:CreateTexture(nil,"ARTWORK")
        self.progressFill = frame:CreateTexture(nil,"OVERLAY")
        self.progressFill:SetPoint("TOPLEFT",self.progressTrack,"TOPLEFT",0,0)
        self.progressFill:SetHeight(3); size(self.progressTrack,384,3)
        self.previous = button(frame,"Previous",18,-334,100,function() local _,err=F.modules.GuideEngine:Back(); if err then F:Print(err) end end)
        self.next = button(frame,"Confirm step",126,-334,130,function() local _,err=F.modules.GuideEngine:Advance(true); if err then F:Print(err) end end)
        self.toggle, self.toggleLabel = button(frame,"Auto advance",264,-334,138,function()
            F.modules.Settings:Set("autoAdvance",not F.settings.autoAdvance)
        end)
        self.chooseGuide = button(frame,"Choose route",264,-334,138,function()
            local engine, ids = F.modules.GuideEngine, {}
            for id in pairs(engine.guides) do ids[#ids+1] = id end
            table.sort(ids)
            if #ids==0 then F:Print("No verified routes installed."); return end
            local index=1
            for i,id in ipairs(ids) do if engine.guide and engine.guide.id == id then index=i % #ids+1 end end
            local _, message = engine:Select(ids[index],F.character)
            if message then F:Print(message) end
        end)
        self.chooseQuest = button(frame,"Choose quest",264,-334,138,function()
            local ok,err=F.modules.LiveJournal:CycleFocus()
            if not ok then F:Print(err) end
        end)
        self.autoCampaign=button(frame,"Auto plan",264,-334,138,function()
            local _,err=F.modules.LevelingCampaign:Auto(F.modules.GuideEngine)
            if err then F:Print(err) end
        end)
        self.professionControls = {}
        local function control(title,x,y,width,fn)
            local item = button(frame,title,x,y,width,function()
                local _, message = fn()
                if message then F:Print(message) end
            end)
            self.professionControls[#self.professionControls+1] = item
            return item
        end
        control("Choose profession",18,-350,174,function()
            local ids = {}
            for id in pairs(F.modules.RecipeDatabase.catalogs) do ids[#ids+1] = id end
            table.sort(ids)
            if #ids == 0 then return nil,"No verified profession catalogs installed." end
            local index = 1
            for i,id in ipairs(ids) do if id == F.character.selectedProfession then index = i % #ids + 1 end end
            return F.modules.ProfessionController:Select(ids[index])
        end)
        control("Target −5",200,-350,98,function()
            local c = F.modules.ProfessionController
            if not c.state then return nil,"Select a profession first." end
            return c:Change("target",math.max(c.catalog.minSkill,c.state.target-5))
        end)
        control("Target +5",306,-350,96,function()
            local c = F.modules.ProfessionController
            if not c.state then return nil,"Select a profession first." end
            return c:Change("target",math.min(c.catalog.maxSkill,c.state.target+5))
        end)
        for i,mode in ipairs({"Farm","Buy","Hybrid"}) do
            local selected = mode
            local b = control(mode,18+(i-1)*128,-386,120,function() return F.modules.ProfessionController:Change("mode",selected) end)
            b.mode = mode
        end
        self.frame = frame
        self:RestorePosition(); self:Render()
    end)
    if not ok then
        if partial and partial.Hide then pcall(partial.Hide, partial) end
        self.frame = nil
        return nil, "UI candidate unsupported: " .. tostring(err)
    end
    return true
end
function U:Show(tab)
    if tab then self.tab = tab end
    local ok, err = self:Build()
    if not ok then F:Print(err); return end
    self:Render(); self.frame:Show()
end
function U:Toggle()
    if self.frame and self.frame:IsShown() then self.frame:Hide() else self:Show() end
end
function U:Render()
    if not self.frame or not F.settings then return end
    local ok, err = pcall(function()
        self.frame:SetScale(F.settings.scale); self.frame:SetAlpha(F.settings.opacity)
        self.companion:SetText(T.companion .. " · " .. T:Note(self.tab))
        self.frame:SetHeight(F.settings.compact and 245 or (self.tab == "professions" and 430 or 380))
        self.body:SetHeight(F.settings.compact and 110 or (self.tab == "professions" and 180 or 160))
        self.footer:ClearAllPoints()
        self.footer:SetPoint("TOPLEFT",self.frame,"TOPLEFT",174,self.tab == "professions" and -306 or -282)
        self.previous:Hide(); self.next:Hide(); self.toggle:Hide()
        self.chooseGuide:Hide(); self.chooseQuest:Hide(); self.autoCampaign:Hide(); self.progressTrack:Hide(); self.progressFill:Hide()
        self.previous.label:SetText("Previous"); self.next.label:SetText("Confirm step")
        for _, control in ipairs(self.professionControls) do control:Hide() end
        if F.settings.compact then self.footer:Hide() else self.footer:Show() end
        if self.tab == "settings" then
            self.heading:SetText("Preferences")
            self.body:SetText(string.format("Auto advance: %s   |   Theme: %s\nScale: %.2f   |   Opacity: %.2f\n\n/fxp theme fog  /fxp theme contrast\n/fxp scale 1.1    /fxp opacity 0.9\n/fxp compact    /fxp auto\n/fxp reset requests confirmation.", tostring(F.settings.autoAdvance),F.settings.theme,F.settings.scale,F.settings.opacity))
            if not F.settings.compact then self.toggle:Show() end
        elseif self.tab == "professions" then
            local c = F.modules.ProfessionController
            self.heading:SetText(c.catalog and c.catalog.title or "Supply ledger")
            if c.catalog then
                local lines = {string.format("Target: %d  |  %s  |  %s estimate",c.state.target,c.state.mode,c.state.estimate or "conservative")}
                if c.error then lines[#lines+1] = c.error end
                if c.plan then
                    lines[#lines+1] = string.format("Skill %d → %d%s",c.plan.current,c.plan.target,c.stale and " (stale plan)" or "")
                    local items = {}; for item,count in pairs(c.plan.materials.raw) do if count > 0 then items[#items+1] = item end end
                    table.sort(items,function(a,b) return tostring(a)<tostring(b) end)
                    for i=1,math.min(4,#items) do
                        local item = items[i]
                        lines[#lines+1] = string.format("%s: need %d · owned used %d · missing %d",tostring(item),c.plan.materials.raw[item],c.plan.materials.used[item] or 0,c.plan.materials.missing[item] or 0)
                    end
                    if #items>4 then lines[#lines+1] = "More materials: /fxp materials" end
                    lines[#lines+1] = c.plan.distribution.costComplete and ("Estimated purchases: " .. c.plan.distribution.cost .. " price units") or "Purchase cost incomplete; manual prices available."
                    if c.plan.trainers[1] then lines[#lines+1] = "Trainer: " .. c.plan.trainers[1] end
                end
                self.body:SetText(table.concat(lines,"\n"))
            else
                self.body:SetText("No profession record is available yet.\n\nFarm · gather what you need\nBuy · prepare a shopping list\nHybrid · gather nearby, buy the rest\n\nChoose a profession once verified content is installed.")
            end
            if not F.settings.compact then for _, control in ipairs(self.professionControls) do control:Show() end end
        else
            local engine = F.modules.GuideEngine
            local step = engine:Current()
            self.heading:SetText(engine.guide and engine.guide.title or "No route selected")
            if not F.settings.compact then self.chooseGuide:Show() end
            if engine.guide then
                local progress = engine:Progress()
                local journal=engine.guide.id==F.modules.LiveJournal.id
                if journal then
                    progress=F.modules.LiveJournal:Progress()
                    if not F.settings.compact then self.chooseGuide:Hide(); self.chooseQuest:Show() end
                end
                self.progressTrack:ClearAllPoints()
                self.progressTrack:SetPoint("TOPLEFT",self.frame,"TOPLEFT",174,F.settings.compact and -232 or -270)
                self.progressTrack:Show()
                if progress>0 then self.progressFill:SetWidth(384*progress/#engine.guide.steps); self.progressFill:Show() end
                local upcoming = engine.guide.steps[engine.index+1]
                if journal then upcoming=F.modules.LiveJournal:NextStep() end
                local ended=progress<#engine.guide.steps and "Route end reached; earlier steps remain reviewable." or "Guide complete"
                local status=string.format("%d / %d completed",progress,#engine.guide.steps)
                if engine.guide.autoResume and step then status=status.." · step "..engine.index end
                local lines={status,"",step and step.text or ended}
                if step and step.minLevel then lines[#lines+1]="Reference minimum level: "..step.minLevel end
                local quest=step and F.snapshot and type(F.snapshot.quests)=="table" and F.snapshot.quests[step.questId]
                if quest and quest.objectives then
                    for i=1,math.min(3,#quest.objectives) do
                        local row=quest.objectives[i]
                        lines[#lines+1]=string.format("%s (%d/%d)",row.text,row.count,row.required)
                    end
                end
                if journal then lines[#lines+1]=engine.state.focusStep and "Focused quest · other progress is retained" or "Objectives first · then turn-ins" end
                lines[#lines+1]=""; lines[#lines+1]=upcoming and ("Next: "..upcoming.text) or ""
                self.body:SetText(table.concat(lines,"\n"))
                if not F.settings.compact then self.previous:Show(); self.next:Show() end
                if engine.guide.campaign then
                    local campaign=F.modules.LevelingCampaign
                    local level=engine.state.campaign and engine.state.campaign.lastLevel
                    local target=engine.guide.campaign.targetLevel
                    local fraction=level and math.max(0,math.min(1,(level-1)/(target-1))) or 0
                    self.progressFill:Hide()
                    if fraction>0 then self.progressFill:SetWidth(384*fraction); self.progressFill:Show() end
                    self.body:SetText(campaign:Text(engine))
                    self.chooseGuide:Hide(); self.chooseQuest:Hide()
                    self.previous.label:SetText("Other quests"); self.next.label:SetText("Defer quest")
                    if not F.settings.compact then self.autoCampaign:Show() end
                end
            else
                self.body:SetText("A quiet road. A new page.\n\n/fxp journal tracks quests already in your log.\nAuthored leveling routes are still being verified.\n\n/fxp tracking checks live quest data.\nDevelopment build · Forever interface 16001")
            end
        end
        local detour = F.modules.Detours.active
        local footer = detour and string.format("Detour: %s · %d/%d\n/fxp detour next or cancel",detour.route.title,detour.index,#detour.route.points) or F.modules.Waypoints:Text()
        local engine=F.modules.GuideEngine
        if not detour and F.persistent and engine.state and type(engine.state.resume)=="table" and (engine.state.resume.deferred or 0)>0 then
            footer=footer.."\nEarlier steps retained · /fxp resume undo"
        end
        self.footer:SetText(footer .. (F.persistent and "" or "\nSession-only progress; original save retained."))
        self:Paint()
    end)
    if not ok then F:Log("UI refresh failed: " .. tostring(err)) end
end
