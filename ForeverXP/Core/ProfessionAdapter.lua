local F = ForeverXP
local A = F:Register("ProfessionAdapter", {source="Questie/Questie@97d7518d5402d185e47b39522a6ea09b8316f0ef"})
local V,C,E=F.modules.Validation,F.modules.Compatibility,F.modules.Events
local function fn(owner,name) return type(owner)=="table" and type(owner[name])=="function" end
local function read(owner,name,...)
    if not fn(owner,name) then return nil end
    local ok,a,b,c,d=pcall(owner[name],...)
    if ok then return a,b,c,d end
end
function A:Matches() return C:Build().interface==16001 and not F.modules.ForeverAdapter.loading end
function A:Known(id)
    local result
    if fn(C_SpellBook,"IsSpellKnown") then result=read(C_SpellBook,"IsSpellKnown",id)
    elseif type(IsPlayerSpell)=="function" then result=read(_G,"IsPlayerSpell",id) end
    if type(result)=="boolean" then return result end
end
function A:Skills()
    if not self:Matches() then return nil,"Profession tracking requires interface 16001 and a loaded world." end
    local modern=fn(C_SkillInfo,"GetNumSkillLines") and fn(C_SkillInfo,"GetSkillLineInfo")
    local owner=modern and C_SkillInfo or _G
    if not fn(owner,"GetNumSkillLines") or not fn(owner,"GetSkillLineInfo") then return nil,"Skill-line APIs unavailable." end
    local count=read(owner,"GetNumSkillLines")
    if not V.Integer(count) or count>512 then return nil,"Skill lines are not ready." end
    -- The inspected reference expands collapsed skill headers before enumeration.
    -- Reverse order avoids shifted indices; never retain chat arguments or poll.
    for i=count,1,-1 do
        local row,header,expanded=read(owner,"GetSkillLineInfo",i)
        local collapsed=modern and type(row)=="table" and row.isHeader==true and row.isCollapsed==true
        if modern and collapsed and fn(owner,"ExpandSkillHeader") then read(owner,"ExpandSkillHeader",i)
        elseif not modern and header==true and expanded==false and fn(owner,"ExpandSkillHeader") then read(owner,"ExpandSkillHeader",0); break end
    end
    count=read(owner,"GetNumSkillLines")
    if not V.Integer(count) or count>512 then return nil,"Skill lines are not ready." end
    local names={}
    for _,catalog in pairs(F.modules.RecipeDatabase.catalogs) do
        if catalog.guide then names[catalog.name]=catalog.skillId end
    end
    local skills={}
    for i=1,count do
        local row,header,_,rank=read(owner,"GetSkillLineInfo",i)
        local id,name
        if modern then
            if type(row)~="table" then return nil,"Incomplete skill lines; previous observation retained." end
            header,rank,id,name=row.isHeader,row.rank,row.skillID,row.name
            if header==true and row.isCollapsed==true then return nil,"Expand profession headers in the Skills window." end
        else name=row; id=names[name] end
        if header~=true and id and V.Integer(rank) then skills[id]=rank end
    end
    return skills
end
function A:Read(profession)
    local guide=F.modules.RecipeDatabase.catalogs[profession]
    if not guide or not guide.guide then return nil end
    local skills,err=self:Skills()
    if not skills then self.error=err; return nil end
    local snapshot={skillsReady=true,skill=skills[guide.skillId],inventory={},knownRecipes={},source=self.source,provenance="source-inspected"}
    local caps={75,150,225,300}
    for i,id in ipairs(guide.rankSpells) do if self:Known(id)==true then snapshot.cap=caps[i] end end
    if snapshot.cap and snapshot.skill and snapshot.cap<snapshot.skill then snapshot.cap=nil end
    local items={}
    for id,recipe in pairs(guide.recipes) do
        snapshot.knownRecipes[id]=self:Known(id)
        for item in pairs(recipe.inputs) do items[item]=true end
        for _,item in ipairs(recipe.tools) do items[item]=true end
    end
    for _,stage in ipairs(guide.stages) do for _,item in ipairs(stage.resources or {}) do items[item]=true end end
    for item in pairs(items) do
        local amount
        if fn(C_Item,"GetItemCount") then amount=read(C_Item,"GetItemCount",item,false,false,false)
        elseif type(GetItemCount)=="function" then amount=read(_G,"GetItemCount",item,false,false,false) end
        if not V.Integer(amount) then snapshot.inventory=nil; break end
        snapshot.inventory[item]=amount
    end
    self.error,self.last=nil,snapshot
    return snapshot
end
function A:Start()
    if self.enabled then return true end
    if C:Build().interface~=16001 then return nil,"Profession tracking requires observed interface 16001." end
    self.enabled=true
    C:RegisterInspectedProvider("professionSnapshot",function(profession) return self:Read(profession) end,self.source)
    for _,event in ipairs({"CHAT_MSG_SKILL","SKILL_LINES_CHANGED","NEW_RECIPE_LEARNED"}) do
        E:On(event,"profession-tracking",function() F.modules.ForeverAdapter:Schedule() end)
    end
    -- Inventory, level and world events share ForeverAdapter's existing coalesced refresh.
    return true
end
