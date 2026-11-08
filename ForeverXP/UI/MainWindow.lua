local F=ForeverXP
local U=F:Register("MainWindow",{tab="guide",width=620,height=420})
local T=F.modules.Themes
local V=F.modules.Validation
local FONT="Fonts\\FRIZQT__.TTF"
local function size(frame,w,h) frame:SetWidth(w); frame:SetHeight(h) end
local function label(parent,x,y,width,font)
    local text=parent:CreateFontString(nil,"OVERLAY")
    text:SetFont(FONT,font or 13); text:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    text:SetWidth(width); text:SetJustifyH("LEFT")
    return text
end
local function block(parent,layer)
    return parent:CreateTexture(nil,layer or "BACKGROUND")
end
function U:RightClick(_,button)
    if button=="RightButton" then F.modules.ContextMenu:Open("root") end
end
function U:SavePosition()
    if not self.frame or not F.character then return end
    local point,_,relativePoint,x,y=self.frame:GetPoint(1)
    F.character.windows.main={point=point,relativePoint=relativePoint,x=x,y=y,width=self.width,height=self.height}
end
function U:RestorePosition()
    local w=F.character and F.character.windows.main
    local points={TOP=true,TOPLEFT=true,TOPRIGHT=true,CENTER=true,LEFT=true,RIGHT=true,BOTTOM=true,BOTTOMLEFT=true,BOTTOMRIGHT=true}
    self.frame:ClearAllPoints()
    if type(w)=="table" and points[w.point] and points[w.relativePoint] and V.Finite(w.x) and V.Finite(w.y) and math.abs(w.x)<10000 and math.abs(w.y)<10000 then
        self.frame:SetPoint(w.point,UIParent,w.relativePoint,w.x,w.y)
    else self.frame:SetPoint("CENTER",UIParent,"CENTER",0,0) end
    local width=type(w)=="table" and w.width or 620
    local height=type(w)=="table" and w.height or 420
    self:ResizeTo(V.Finite(width) and width or 620,V.Finite(height) and height or 420,false)
end
function U:ResizeTo(width,height,save)
    if not V.Finite(width) or not V.Finite(height) then return nil,"Supply finite window dimensions." end
    self.width=math.floor(math.max(380,math.min(980,width)))
    self.height=math.floor(math.max(260,math.min(820,height)))
    self.inLayout=true
    size(self.frame,self.width,self.height)
    self.inLayout=false
    self:Layout()
    if save then self:SavePosition() end
    self:Render()
    return true
end
function U:Scroll(delta)
    if not self.scroll.SetVerticalScroll then return end
    self.scrollOffset=math.max(0,math.min(self.scrollRange or 0,(self.scrollOffset or 0)-delta*36))
    self.scroll:SetVerticalScroll(self.scrollOffset)
end
function U:Layout()
    if not self.frame or not F.settings then return end
    local w,h=self.width,self.height
    local small=F.settings.compact or h<320 or w<480
    local top=small and 62 or 88
    self.cardTop,self.cardHeight=top,h-top-82
    local cw=w-40
    self.contentWidth=cw-36
    self.title:SetWidth(w-56); self.companion:SetWidth(w-56)
    if small then self.companion:Hide() else self.companion:Show() end
    self.viewLabel:SetWidth(w-56)
    self.viewLabel:ClearAllPoints(); self.viewLabel:SetPoint("TOPLEFT",self.frame,"TOPLEFT",24,small and -43 or -66)
    self.card:ClearAllPoints(); self.card:SetPoint("TOPLEFT",self.frame,"TOPLEFT",20,-top); size(self.card,cw,self.cardHeight)
    size(self.rail,2,self.cardHeight)
    self.eyebrow:SetWidth(self.contentWidth); self.heading:SetWidth(self.contentWidth)
    self.meta:SetWidth(self.contentWidth)
    local bodyTop=small and 66 or 82
    self.heading:ClearAllPoints(); self.heading:SetPoint("TOPLEFT",self.card,"TOPLEFT",18,small and -25 or -30)
    self.meta:ClearAllPoints(); self.meta:SetPoint("TOPLEFT",self.card,"TOPLEFT",18,small and -48 or -57)
    self.scroll:ClearAllPoints(); self.scroll:SetPoint("TOPLEFT",self.card,"TOPLEFT",18,-bodyTop)
    self.viewportHeight=math.max(8,self.cardHeight-bodyTop-38)
    size(self.scroll,self.contentWidth,self.viewportHeight); self.content:SetWidth(self.contentWidth)
    self.body:SetWidth(self.contentWidth)
    self.progressTrack:ClearAllPoints(); self.progressTrack:SetPoint("BOTTOMLEFT",self.card,"BOTTOMLEFT",18,14)
    size(self.progressTrack,self.contentWidth,4)
    self.progressFill:SetHeight(4)
    self.progressCaption:ClearAllPoints(); self.progressCaption:SetPoint("BOTTOMLEFT",self.card,"BOTTOMLEFT",18,23); self.progressCaption:SetWidth(self.contentWidth)
    self.nav:ClearAllPoints(); self.nav:SetPoint("TOPLEFT",self.frame,"TOPLEFT",24,-(h-72)); size(self.nav,w-48,42)
    self.navTitle:SetWidth(w-124); self.footer:SetWidth(w-124)
    self.hint:ClearAllPoints(); self.hint:SetPoint("BOTTOMLEFT",self.frame,"BOTTOMLEFT",24,12); self.hint:SetWidth(w-48)
    self.shadow:ClearAllPoints(); self.shadow:SetPoint("TOPLEFT",self.frame,"TOPLEFT",4,-4); size(self.shadow,w,h)
    self.edge:SetWidth(w)
    self.trim[1]:SetHeight(h); self.trim[2]:SetHeight(h); self.trim[3]:SetWidth(w)
    for i,line in ipairs(self.fog) do line:SetWidth(cw); line:ClearAllPoints(); line:SetPoint("TOPLEFT",self.card,"TOPLEFT",0,-18*i) end
    if F.settings.locked then self.resizeGrip:Hide() else self.resizeGrip:Show() end
    self.frame:SetMovable(not F.settings.locked)
    if self.frame.SetResizable then self.frame:SetResizable(not F.settings.locked) end
end
function U:Paint()
    local t=T:Get()
    T:Texture(self.background,t.panel); T:Texture(self.shadow,{0,0,0,0.35}); T:Texture(self.cardBackground,t.card or t.panel)
    T:Texture(self.edge,t.accent); T:Texture(self.rail,t.border)
    for _,edge in ipairs(self.trim) do T:Texture(edge,t.border) end
    for _,line in ipairs(self.fog) do T:Texture(line,t.fog) end
    for _,line in ipairs(self.gripLines) do T:Texture(line,t.chromeText or t.muted) end
    local chrome=t.chromeText or t.muted
    T:Text(self.title,t.headerText or t.text); T:Text(self.companion,chrome); T:Text(self.viewLabel,chrome)
    T:Text(self.eyebrow,t.accent); T:Text(self.heading,t.accent); T:Text(self.meta,t.muted); T:Text(self.body,t.text)
    if self.adviceSeverity then
        local alert=self.adviceSeverity=="danger" and t.danger or t.warning
        T:Text(self.eyebrow,alert); T:Texture(self.rail,alert)
    end
    T:Text(self.progressCaption,t.muted); T:Text(self.navTitle,t.headerText or t.text); T:Text(self.footer,chrome); T:Text(self.hint,chrome)
    T:Text(self.navGlyph,t.progress)
    T:Texture(self.progressTrack,t.track); T:Texture(self.progressFill,t.progress)
    self.title:SetFont(t.titleFont or FONT,20)
    self.eyebrow:SetFont(FONT,10); self.heading:SetFont(FONT,F.settings.fontSize+(self.width<480 and 2 or 5))
    self.body:SetFont(FONT,F.settings.fontSize); self.meta:SetFont(FONT,11)
    self.companion:SetFont(FONT,11); self.viewLabel:SetFont(FONT,10); self.progressCaption:SetFont(FONT,10)
    self.navTitle:SetFont(FONT,12); self.footer:SetFont(FONT,10); self.hint:SetFont(FONT,10)
    if self.navArrow.SetVertexColor then self.navArrow:SetVertexColor(t.progress[1],t.progress[2],t.progress[3]) end
    if F.modules.ContextMenu then F.modules.ContextMenu:Paint() end
end
function U:View()
    local G=F.modules.GuideEngine
    if self.tab=="settings" then
        return {heading="Make it your own",eyebrow="PREFERENCES",meta=T:Get().name.." theme",fraction=0,
            text="Right-click anywhere in this window to open the menu.\n\nChoose your theme, guide, profession, text size and navigation preferences there.\n\nDrag the header to move the window. Drag the lower-right corner to resize it. Scroll inside the objective card for longer instructions.\n\nWindow position and size are saved for this character. Theme and text preferences are shared.",progress="Appearance & window controls"}
    elseif self.tab=="professions" then
        local C=F.modules.ProfessionController
        if not C.catalog then return {heading="Choose your profession",eyebrow="PROFESSIONS",meta="Twelve Classic guides · skill 1–300",fraction=0,text="Open the right-click menu and choose a profession to begin. Your guide will follow your observed skill and materials.",progress="Skill tracking"} end
        if C.catalog.guide then
            local plan=C.plan
            local fraction=plan and plan.current and math.max(0,math.min(1,(plan.current-1)/math.max(1,C.state.target-1))) or 0
            if plan and plan.status=="target-reached" then fraction=1 end
            return {heading=plan and plan.recipe and plan.recipe.name or C.catalog.name,eyebrow=C.catalog.name:upper().."  /  "..(C.catalog.kind=="craft" and "CRAFTING" or "GATHERING"),meta="Target "..C.state.target.." · "..(C.stale and "Waiting for live data" or "Skill & materials tracking"),
                text=F.modules.ProfessionGuides:Text(C),fraction=fraction,progress=plan and plan.current and ("SKILL "..plan.current.." / "..C.state.target) or "Waiting for observed skill"}
        end
        local lines={C.error or "Authored profession plan"}
        if C.plan then
            lines[#lines+1]="Skill "..C.plan.current.." → "..C.plan.target..(C.stale and " · stale plan" or "")
            for item,count in pairs(C.plan.materials.missing) do lines[#lines+1]=tostring(item)..": missing "..count end
        end
        return {heading=C.catalog.title,eyebrow="PROFESSION PLAN",meta=C.state.mode,text=table.concat(lines,"\n"),fraction=0,progress="Target "..C.state.target}
    end
    local step=G:Current()
    if not G.guide then return {heading="Your next chapter",eyebrow="LEVELING",meta="Choose a guide from the right-click menu",fraction=0,text="A quiet road. A new page.\n\nChoose your faction’s leveling guide, or open the live quest journal to follow quests already in your log.",progress="No route selected"} end
    local observed=step and F.snapshot and F.snapshot.quests and F.snapshot.quests[step.questId]
    local title=type(observed)=="table" and V.String(observed.title) and observed.title or nil
    local reference=step and F.modules.QuestAdvice.records[step.questId]
    local labels={ACCEPT_QUEST="ACCEPT QUEST",COMPLETE_QUEST="OBJECTIVES",TURN_IN_QUEST="TURN IN QUEST",REACH_LEVEL="LEVEL GOAL"}
    local result={heading=step and (title or step.questTitle or (reference and reference.title) or step.text) or G.guide.title,eyebrow=step and (labels[step.type] or "NEXT STEP") or "GUIDE",meta=G.guide.title,fraction=G:Progress()/#G.guide.steps,progress=G:Progress().." completed"}
    if G.guide.campaign then
        local c=F.modules.LevelingCampaign
        local level=G.state.campaign and G.state.campaign.lastLevel
        result.text=c:Text(G)
        local run=c.runtime[G.guide.id]
        if run and run.state==G.state and run.route then
            local route=run.route
            result.meta=route.stage and (route.stage.title.." · "..#route.tasks.." ready in batch") or (route.status=="waiting" and "Route waiting · check local alternatives" or "Local route alternative")
            result.routeContext=F.modules.RoutePlanner:Text(route,run.selected)
        end
        result.fraction=level and math.max(0,math.min(1,(level-1)/(G.guide.campaign.targetLevel-1))) or 0
        result.progress=level and ("LEVEL "..level.." / "..G.guide.campaign.targetLevel) or "Waiting for observed level"
    else
        local lines={step and step.text or "Current chapter complete."}
        local q=step and F.snapshot and F.snapshot.quests and F.snapshot.quests[step.questId]
        if q and type(q.objectives)=="table" then for _,row in ipairs(q.objectives) do lines[#lines+1]=string.format("%s (%d/%d)",row.text,row.count,row.required) end end
        result.text=table.concat(lines,"\n\n")
    end
    local advice=F.modules.QuestAdvice:For(step,F.snapshot)
    result.advice=advice
    if advice.badge then result.eyebrow=result.eyebrow.." · WARNING: "..advice.badge end
    local notes=F.modules.QuestAdvice:Text(advice)
    if notes~="" or (result.routeContext and result.routeContext~="") then
        local first,remaining=(result.text or ""):match("^([^\n]*)\n?(.*)$")
        local blocks={first or ""}
        if result.routeContext and result.routeContext~="" then blocks[#blocks+1]=result.routeContext end
        if notes~="" then blocks[#blocks+1]=notes end
        if remaining and remaining~="" then blocks[#blocks+1]=remaining end
        result.text=table.concat(blocks,"\n\n")
    end
    return result
end
function U:RenderNavigation()
    if not self.frame then return end
    self.navArrow:Hide(); self.navGlyph:Show()
    if self.tab~="guide" then
        self.navGlyph:SetText(self.tab=="professions" and "+" or "*")
        self.navTitle:SetText(self.tab=="professions" and "Your next skill point" or T:Get().name)
        self.footer:SetText(self.tab=="professions" and "Recipes, targets and materials are in the right-click menu." or "Choose Appearance in the right-click menu to switch themes.")
        return
    end
    local w=F.modules.Waypoints.current
    if not w or not F.settings.waypoints then self.navGlyph:SetText("·"); self.navTitle:SetText("No navigation target"); self.footer:SetText("Choose a guide or quest from the menu."); return end
    self.navTitle:SetText(string.format("%s · %.1f, %.1f",tostring(w.zone),w.x*100,w.y*100))
    local n=F.modules.Navigation and F.modules.Navigation.state
    local note=w.verification=="reference-reviewed" and "Reference location" or "Waypoint"
    if n and n.distance then
        note=note.." · "..math.floor(n.distance+0.5).." yd straight-line"
        if n.rotation and self.navArrow.SetRotation and F.settings.arrow then
            self.navArrow:SetRotation(n.rotation); self.navArrow:Show(); self.navGlyph:Hide()
        else self.navGlyph:SetText(n.cardinal or "·") end
    else self.navGlyph:SetText("·"); note=note.." · "..(n and n.message or "Coordinates") end
    self.footer:SetText(note)
end
function U:Render()
    if not self.frame or not F.settings or self.rendering then return end
    self.rendering=true
    local ok,err=pcall(function()
        self.frame:SetScale(F.settings.scale); self.frame:SetAlpha(F.settings.opacity)
        self.companion:SetText(T.companion.." · "..T:Note(self.tab)); self.title:SetText("FOREVER XP")
        self.viewLabel:SetText(({guide="FIELD GUIDE",professions="PROFESSIONS",settings="PREFERENCES"})[self.tab])
        local view=self:View()
        self.adviceSeverity=view.advice and view.advice.severity
        self.eyebrow:SetText(view.eyebrow); self.heading:SetText(view.heading); self.meta:SetText(view.meta)
        self.body:SetText(view.text or ""); self.progressCaption:SetText(view.progress or "")
        self:Layout(); self:Paint()
        self.progressFill:SetWidth(math.max(1,self.contentWidth*(view.fraction or 0)))
        if (view.fraction or 0)>0 then self.progressFill:Show() else self.progressFill:Hide() end
        local height=self.body.GetStringHeight and self.body:GetStringHeight() or 200
        if not V.Finite(height) then height=200 end
        self.body:SetHeight(height+8); self.content:SetHeight(math.max(self.viewportHeight,height+8))
        self.scrollRange=math.max(0,height+8-self.viewportHeight)
        if self.lastText~=view.text then self.scrollOffset=0; self.lastText=view.text end
        self.scrollOffset=math.min(self.scrollOffset or 0,self.scrollRange)
        if self.scroll.SetVerticalScroll then self.scroll:SetVerticalScroll(self.scrollOffset) end
        local scrollHint=self.scrollRange>0 and " · scroll for more" or ""
        self.hint:SetText("Right-click for menu"..scrollHint..(F.settings.locked and " · window locked" or " · drag corner to resize"))
        self:RenderNavigation()
        if F.modules.Navigation then F.modules.Navigation:EnsureTick() end
    end)
    self.rendering=false
    if not ok then F:Log("UI refresh failed: "..tostring(err)) end
end
function U:Build()
    if self.frame then return true end
    if type(CreateFrame)~="function" or not UIParent then return nil,"UI frame API unavailable" end
    local partial
    local ok,err=pcall(function()
        local frame=CreateFrame("Frame","ForeverXPWindow",UIParent); partial=frame; self.frame=frame
        frame:SetFrameStrata("MEDIUM"); frame:SetClampedToScreen(true); frame:EnableMouse(true); frame:SetMovable(true)
        if frame.SetResizable then frame:SetResizable(true) end
        if frame.SetResizeBounds then frame:SetResizeBounds(380,260,980,820)
        elseif frame.SetMinResize then frame:SetMinResize(380,260); if frame.SetMaxResize then frame:SetMaxResize(980,820) end end
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart",function() if not F.settings.locked then frame:StartMoving() end end)
        frame:SetScript("OnDragStop",function() frame:StopMovingOrSizing(); U:SavePosition() end)
        frame:SetScript("OnMouseUp",function(_,button) U:RightClick(nil,button) end)
        frame:SetScript("OnHide",function() F.modules.ContextMenu:Close() end)
        frame:SetScript("OnSizeChanged",function(_,w,h) if not U.inLayout and V.Finite(w) and V.Finite(h) then U:ResizeTo(w,h,false) end end)
        self.shadow=block(frame); self.background=block(frame); self.background:SetAllPoints(frame)
        self.edge=block(frame,"ARTWORK"); self.edge:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0); self.edge:SetHeight(3)
        self.trim={}
        for _,spec in ipairs({{"TOPLEFT",2,420},{"TOPRIGHT",2,420},{"BOTTOMLEFT",620,2}}) do local edge=block(frame,"ARTWORK"); edge:SetPoint(spec[1],frame,spec[1],0,0); size(edge,spec[2],spec[3]); self.trim[#self.trim+1]=edge end
        self.title=label(frame,24,-18,560,20); self.companion=label(frame,24,-46,560,11); self.viewLabel=label(frame,24,-66,560,10)
        self.card=CreateFrame("Frame",nil,frame)
        self.cardBackground=block(self.card); self.cardBackground:SetAllPoints(self.card)
        self.rail=block(self.card,"ARTWORK"); self.rail:SetPoint("TOPLEFT",self.card,"TOPLEFT",0,0); self.rail:SetWidth(2)
        self.fog={}; for i=1,12 do local line=block(self.card,"BORDER"); line:SetHeight(1); self.fog[#self.fog+1]=line end
        self.eyebrow=label(self.card,18,-12,500,10); self.heading=label(self.card,18,-30,500,18); self.heading:SetHeight(25)
        self.meta=label(self.card,18,-57,500,11); self.meta:SetHeight(18)
        self.scroll=CreateFrame("ScrollFrame",nil,self.card); self.content=CreateFrame("Frame",nil,self.scroll)
        self.content:SetPoint("TOPLEFT",self.scroll,"TOPLEFT",0,0)
        self.body=label(self.content,0,0,500,13)
        if self.scroll.SetScrollChild then self.scroll:SetScrollChild(self.content) end
        if self.scroll.EnableMouseWheel then self.scroll:EnableMouseWheel(true) end
        self.scroll:SetScript("OnMouseWheel",function(_,delta) U:Scroll(delta) end)
        self.scroll:EnableMouse(true); self.scroll:SetScript("OnMouseUp",function(_,button) U:RightClick(nil,button) end)
        self.progressTrack=block(self.card,"ARTWORK"); self.progressFill=block(self.card,"OVERLAY"); self.progressFill:SetPoint("TOPLEFT",self.progressTrack,"TOPLEFT",0,0)
        self.progressCaption=label(self.card,18,-200,500,10)
        self.nav=CreateFrame("Frame",nil,frame)
        self.navGlyph=label(self.nav,0,-3,34,22); self.navGlyph:SetHeight(34)
        self.navArrow=block(self.nav,"ARTWORK"); self.navArrow:SetPoint("TOPLEFT",self.nav,"TOPLEFT",0,-3); size(self.navArrow,28,28)
        self.navArrow:SetTexture("Interface\\AddOns\\ForeverXP\\Assets\\NavigationArrow.tga"); self.navArrow:Hide()
        self.navTitle=label(self.nav,40,0,480,12); self.footer=label(self.nav,40,-19,480,10); self.footer:SetHeight(24)
        self.hint=label(frame,24,-400,540,10)
        self.resizeGrip=CreateFrame("Frame",nil,frame); size(self.resizeGrip,20,20); self.resizeGrip:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",-3,3); self.resizeGrip:EnableMouse(true)
        self.gripLines={}; for i=1,3 do local line=block(self.resizeGrip,"ARTWORK"); line:SetPoint("BOTTOMRIGHT",self.resizeGrip,"BOTTOMRIGHT",-3,3+i*4); size(line,16-i*4,1); self.gripLines[#self.gripLines+1]=line end
        self.resizeGrip:SetScript("OnMouseDown",function(_,button)
            if button=="RightButton" then U:RightClick(nil,button)
            elseif button=="LeftButton" and not F.settings.locked and frame.StartSizing then frame:StartSizing("BOTTOMRIGHT") end
        end)
        self.resizeGrip:SetScript("OnMouseUp",function() frame:StopMovingOrSizing(); U:SavePosition() end)
        if type(UISpecialFrames)=="table" then UISpecialFrames[#UISpecialFrames+1]="ForeverXPWindow" end
        self:RestorePosition(); self:Render()
    end)
    if not ok then if partial and partial.Hide then pcall(partial.Hide,partial) end; self.frame=nil; return nil,"UI unsupported: "..tostring(err) end
    return true
end
function U:Show(tab)
    if tab then self.tab=tab end
    if self.tab=="professions" and F.initialized and not F.modules.ProfessionController.catalog then F.modules.ProfessionController:Default() end
    local ok,err=self:Build(); if not ok then F:Print(err); return end
    self.frame:Show(); self:Render()
end
function U:Toggle() if self.frame and self.frame:IsShown() then self.frame:Hide() else self:Show() end end
