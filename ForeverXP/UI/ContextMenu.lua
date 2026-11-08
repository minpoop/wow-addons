local F=ForeverXP
local M=F:Register("ContextMenu",{page="root",rows={}})
local function entry(id,label,run,checked) return {id=id,label=label,run=run,checked=checked} end
local function submenu(id,label,page) return {id=id,label=label,page=page} end
local function command(text) return function() F:Command(text) end end
function M:Items(page)
    local U,S,C,G=F.modules.MainWindow,F.modules.Settings,F.modules.ProfessionController,F.modules.GuideEngine
    local items={}
    if page~="root" then items[1]=submenu("back","< Back","root") end
    local function add(item) items[#items+1]=item end
    if page=="root" then
        add(entry("view-guide","Leveling guide",function() U:Show("guide") end,U.tab=="guide"))
        add(entry("view-professions","Profession guide",function() U:Show("professions") end,U.tab=="professions"))
        add(entry("view-settings","Preferences",function() U:Show("settings") end,U.tab=="settings"))
        add(submenu("guides","Leveling actions","guides"))
        add(submenu("professions","Choose profession","professions"))
        if C.catalog then add(submenu("profession-actions","Profession actions","profession-actions")) end
        add(submenu("themes","Appearance","themes"))
        add(submenu("navigation","Navigation","navigation"))
        add(submenu("display","Window & text","display"))
        add(entry("hide","Hide window",function() U.frame:Hide() end))
    elseif page=="guides" then
        add(entry("leveling","Recommended faction guide",command("leveling")))
        add(entry("alliance","Alliance 1–60",function() local ok,err=F.modules.LevelingCampaign:Select(F.modules.LevelingCampaign.id); if not ok then F:Print(err) end; U:Show("guide") end))
        if F.modules.LevelingCampaign.hordeId then add(entry("horde","Horde 1–60",command("horde"))) end
        add(entry("journal","Live quest journal",command("journal")))
        add(submenu("library","Earlier reference guides","library"))
        if G.guide then
            local journal=G.guide.id==F.modules.LiveJournal.id
            add(entry("other-quest",G.guide.campaign and "Other suitable quest" or (journal and "Other logged quest" or "Previous step"),function()
                local _,err
                if journal then _,err=F.modules.LiveJournal:CycleFocus() else _,err=G:Back() end
                if err then F:Print(err) end
            end))
            add(entry("defer",G.guide.campaign and "Defer current quest" or "Confirm current step",function() local _,err=G:Advance(true); if err then F:Print(err) end end))
            if G.guide.campaign then
                add(entry("auto-plan","Resume automatic plan",function() F.modules.LevelingCampaign:Auto(G) end))
                add(entry("chapters","Print chapter summaries",command("leveling chapters")))
                add(entry("unfinished","Print unfinished quests",command("leveling quests")))
            else
                add(entry("skip","Skip optional step",function() local _,err=G:Skip(); if err then F:Print(err) end end))
            end
            add(entry("auto-advance","Automatic progression",function() S:Set("autoAdvance",not F.settings.autoAdvance) end,F.settings.autoAdvance))
        end
    elseif page=="library" then
        add(entry("elwynn","Elwynn shared route",command("elwynn")))
        add(entry("test-campaign","Alliance 1–20 test",command("1-20")))
    elseif page=="professions" then
        local ids={}; for id in pairs(F.modules.RecipeDatabase.catalogs) do ids[#ids+1]=id end; table.sort(ids)
        for _,id in ipairs(ids) do
            local selected=id; local catalog=F.modules.RecipeDatabase.catalogs[id]
            add(entry("profession-"..id,catalog.name or catalog.title,function()
                local ok,err=C:Select(selected); if ok then U:Show("professions") else F:Print(err) end
            end,C.catalog and C.catalog.id==id))
        end
    elseif page=="profession-actions" and C.catalog then
        add(submenu("targets","Target skill","targets"))
        add(entry("target-down","Target −5",function() C:Change("target",math.max(C.catalog.minSkill,C.state.target-5)) end))
        add(entry("target-up","Target +5",function() C:Change("target",math.min(C.catalog.maxSkill,C.state.target+5)) end))
        if C.catalog.kind~="gather" then
            add(submenu("recipes","Choose recipe","recipes"))
            add(submenu("batch","Crafting batch","batch"))
            add(submenu("modes","Farm / Buy / Hybrid","modes"))
            add(entry("materials","Print material list",command("materials")))
        end
    elseif page=="targets" and C.catalog then
        for _,value in ipairs({75,150,225,300}) do
            if value<=C.catalog.maxSkill then local target=value; add(entry("target-"..value,tostring(value),function() C:Change("target",target) end,C.state.target==value)) end
        end
    elseif page=="batch" and C.state then
        add(entry("batch-down","One fewer craft",function() C:Change("batch",math.max(1,(C.state.batch or 5)-1)) end))
        add(entry("batch-up","One more craft",function() C:Change("batch",math.min(20,(C.state.batch or 5)+1)) end))
        for _,value in ipairs({1,5,10,20}) do local count=value; add(entry("batch-"..value,value.." craft(s)",function() C:Change("batch",count) end,(C.state.batch or 5)==value)) end
    elseif page=="recipes" and C.plan and C.plan.stage then
        for _,id in ipairs(C.plan.stage.choices or {}) do
            local recipe=id
            add(entry("recipe-"..id,C.catalog.recipes[id].name,function()
                C.state.preferredRecipes=C.state.preferredRecipes or {}; C.state.preferredRecipes[C.plan.stage.id]=recipe; C:Refresh()
            end,C.plan.recipeId==id))
        end
    elseif page=="modes" and C.state then
        for _,name in ipairs({"Farm","Buy","Hybrid"}) do local mode=name; add(entry("mode-"..name,name,function() C:Change("mode",mode) end,C.state.mode==name)) end
    elseif page=="themes" then
        for _,choice in ipairs(F.modules.Themes.options) do local id=choice.id; add(entry("theme-"..id,choice.name,function() S:Set("theme",id) end,F.settings.theme==id)) end
    elseif page=="navigation" then
        add(entry("arrow","Direction arrow",function() S:Set("arrow",not F.settings.arrow) end,F.settings.arrow))
        add(entry("coordinates","Show coordinates",function() S:Set("waypoints",not F.settings.waypoints) end,F.settings.waypoints))
        add(entry("show-map","Show target on world map",function()
            local ok,err=F.modules.Navigation:ShowMap(); if not ok then F:Print(err) end
        end))
        add(entry("clear-waypoint","Clear navigation target",function() F.modules.Waypoints:Set(nil) end))
    elseif page=="display" then
        add(entry("locked","Lock position & size",function() S:Set("locked",not F.settings.locked) end,F.settings.locked))
        add(entry("compact","Compact spacing",function() S:Set("compact",not F.settings.compact) end,F.settings.compact))
        for _,n in ipairs({11,13,15}) do local font=n; add(entry("font-"..n,"Text size "..n,function() S:Set("fontSize",font) end,F.settings.fontSize==n)) end
        add(entry("small","Small window",function() U:ResizeTo(420,300,true) end))
        add(entry("standard","Standard window",function() U:ResizeTo(620,420,true) end))
        add(entry("large","Large window",function() U:ResizeTo(800,560,true) end))
        add(entry("opacity","Toggle transparency",function() S:Set("opacity",F.settings.opacity<1 and 1 or 0.85) end,F.settings.opacity==1))
    end
    return items
end
function M:Close()
    if self.frame then self.frame:Hide() end
    if self.overlay then self.overlay:Hide() end
end
function M:Invoke(id)
    for _,item in ipairs(self.items or self:Items(self.page)) do
        if item.id==id then
            if item.page then return self:Open(item.page) end
            self:Close()
            local ok,err=pcall(item.run)
            if not ok then F:Log("Menu action failed: "..tostring(err)); return nil,err end
            return true
        end
    end
    return nil,"Menu action unavailable."
end
function M:Build()
    if self.frame then return end
    local T=F.modules.Themes
    self.overlay=CreateFrame("Frame",nil,UIParent); self.overlay:SetAllPoints(UIParent)
    self.overlay:SetFrameStrata("DIALOG"); self.overlay:SetFrameLevel(80); self.overlay:EnableMouse(true)
    self.overlay:SetScript("OnMouseDown",function() M:Close() end)
    local frame=CreateFrame("Frame","ForeverXPContextMenu",UIParent); self.frame=frame
    frame:SetFrameStrata("DIALOG"); frame:SetFrameLevel(90); frame:SetClampedToScreen(true); frame:EnableMouse(true)
    frame:SetScript("OnHide",function() M.overlay:Hide() end)
    self.background=frame:CreateTexture(nil,"BACKGROUND"); self.background:SetAllPoints(frame)
    self.border=frame:CreateTexture(nil,"ARTWORK"); self.border:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0); self.border:SetWidth(282); self.border:SetHeight(2)
    self.title=frame:CreateFontString(nil,"OVERLAY"); self.title:SetFont("Fonts\\FRIZQT__.TTF",14)
    self.title:SetPoint("TOPLEFT",frame,"TOPLEFT",14,-12); self.title:SetText("FOREVER XP")
    if type(UISpecialFrames)=="table" then UISpecialFrames[#UISpecialFrames+1]="ForeverXPContextMenu" end
    self:Close()
end
function M:Paint()
    if not self.frame then return end
    local T=F.modules.Themes; local theme=T:Get()
    T:Texture(self.background,theme.card or theme.panel); T:Texture(self.border,theme.border); T:Text(self.title,theme.accent)
    for i,row in ipairs(self.rows) do
        local item=self.items and self.items[i]
        if item then T:Texture(row.background,item.checked and theme.selected or (theme.card or theme.panel)); T:Text(row.label,item.checked and theme.accent or theme.text); T:Text(row.mark,theme.accent) end
    end
end
function M:Open(page)
    self:Build(); self.page=page or "root"; self.items=self:Items(self.page)
    local titles={root="FOREVER XP",guides="LEVELING ACTIONS",library="REFERENCE GUIDES",professions="CHOOSE PROFESSION",["profession-actions"]="PROFESSION ACTIONS",themes="APPEARANCE",navigation="NAVIGATION",display="WINDOW & TEXT",targets="TARGET SKILL",batch="CRAFTING BATCH",recipes="CHOOSE RECIPE",modes="MATERIAL PLANNING"}
    self.title:SetText(titles[self.page] or "FOREVER XP")
    for i,item in ipairs(self.items) do
        local row=self.rows[i]
        if not row then
            row=CreateFrame("Button",nil,self.frame); self.rows[i]=row
            row:SetWidth(262); row:SetHeight(26); row:SetPoint("TOPLEFT",self.frame,"TOPLEFT",10,-40-(i-1)*27)
            row.background=row:CreateTexture(nil,"BACKGROUND"); row.background:SetAllPoints(row)
            row.label=row:CreateFontString(nil,"OVERLAY"); row.label:SetFont("Fonts\\FRIZQT__.TTF",12); row.label:SetPoint("TOPLEFT",row,"TOPLEFT",9,-6); row.label:SetWidth(223); row.label:SetHeight(18); row.label:SetJustifyH("LEFT")
            row.mark=row:CreateFontString(nil,"OVERLAY"); row.mark:SetFont("Fonts\\FRIZQT__.TTF",12); row.mark:SetPoint("TOPRIGHT",row,"TOPRIGHT",-8,-6)
            local position=i
            row:SetScript("OnClick",function() local selected=M.items[position]; if selected then M:Invoke(selected.id) end end)
            row:SetScript("OnEnter",function() F.modules.Themes:Texture(row.background,F.modules.Themes:Get().hover) end)
            row:SetScript("OnLeave",function() M:Paint() end)
        end
        row.label:SetText(item.label); row.mark:SetText(item.page and ">" or (item.checked and "*" or "")); row:Show()
    end
    for i=#self.items+1,#self.rows do self.rows[i]:Hide() end
    self.frame:SetWidth(282); self.frame:SetHeight(49+#self.items*27)
    self.frame:ClearAllPoints()
    local readable,x,y=pcall(function() return GetCursorPosition() end)
    local scale=UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
    if readable and type(x)=="number" and type(y)=="number" and scale>0 then self.frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",x/scale,y/scale)
    else self.frame:SetPoint("TOPRIGHT",F.modules.MainWindow.frame,"TOPRIGHT",-12,-50) end
    self:Paint(); self.overlay:Show(); self.frame:Show()
    return true
end
