local F=ForeverXP
local R=F:Register("RunTracker",{})
local V,E=F.modules.Validation,F.modules.Events
local counters={"samples","xpGained","unknownXPIntervals","seconds","turnIns","zoneChanges","routeWaits","decisions"}
local function read(name,...)
    if type(_G[name])~="function" then return end
    local ok,value=pcall(_G[name],...);if ok then return value end
end
function R:Validate(data)
    if type(data)~="table" or not V.DataOnly(data) or data.version~=1 or type(data.active)~="boolean"
       or not V.Array(data.events) or #data.events>80 or type(data.quests)~="table"
       or not V.Integer(data.firstLevel,1) or not V.Integer(data.lastLevel,1) then return nil,"Invalid or newer run report retained." end
    for _,key in ipairs(counters) do
        if (key=="seconds" and (not V.Finite(data[key]) or data[key]<0)) or (key~="seconds" and not V.Integer(data[key])) then return nil,"Invalid run counters retained." end
    end
    if data.plan~=nil and not V.String(data.plan) then return nil,"Invalid run plan retained." end
    for _,key in ipairs({"xpAvailable","clockAvailable"}) do if data[key]~=nil and type(data[key])~="boolean" then return nil,"Invalid run availability retained." end end
    if data.xpAvailable and (not V.Integer(data.currentXP) or not V.Integer(data.currentXPMax,1) or data.currentXP>data.currentXPMax) then return nil,"Invalid run XP retained." end
    local count=0
    for id,value in pairs(data.quests) do count=count+1;if count>2048 or not V.Integer(id,1) or value~=true then return nil,"Invalid run quest records retained." end end
    for _,row in ipairs(data.events) do
        if type(row)~="table" or not V.String(row.kind) or not V.String(row.text) then return nil,"Invalid run trace retained." end
    end
    return true
end
function R:Data()
    local rebound=self.owner~=F.character
    if rebound then self:Pause();self.owner=F.character end
    local data=F.character and F.character.routeRun
    if data==nil then return nil,"Start a local run with /fxp run start." end
    local valid,err=self:Validate(data);if not valid then return nil,err end
    if rebound and data.active and data.samples>0 then data.unknownXPIntervals=data.unknownXPIntervals+1 end
    return data
end
function R:Pause()
    self.lastTime,self.lastXP,self.previousQuests,self.lastDecision,self.lastZone,self.waitKey=nil,nil,nil,nil,nil,nil
end
function R:Clock(data)
    local now=read("GetTime")
    if V.Finite(now) and now>=0 then
        if self.lastTime and now>=self.lastTime then data.seconds=data.seconds+now-self.lastTime end
        self.lastTime=now;data.clockAvailable=true
    else self.lastTime=nil;data.clockAvailable=false end
end
function R:Event(data,kind,text)
    data.events[#data.events+1]={kind=kind,text=text}
    if #data.events>80 then table.remove(data.events,1) end
end
function R:XP(data)
    local level,xp,maximum
    if F.modules.Compatibility:Build().interface==16001 then
        level,xp,maximum=read("UnitLevel","player"),read("UnitXP","player"),read("UnitXPMax","player")
    end
    if not V.Integer(level,1) or not V.Integer(xp) or not V.Integer(maximum,1) or xp>maximum then
        if self.lastXP then data.unknownXPIntervals=data.unknownXPIntervals+1 end
        self.lastXP=nil;data.xpAvailable=false;return
    end
    data.xpAvailable=true;data.currentXP=xp;data.currentXPMax=maximum
    if data.lastLevel~=level then self:Event(data,"level","Observed level "..level);data.lastLevel=level end
    local old=self.lastXP
    if old then
        local delta
        if level==old.level and maximum==old.maximum and xp>=old.xp then delta=xp-old.xp
        elseif level==old.level+1 then delta=old.maximum-old.xp+xp end
        if delta then data.xpGained=data.xpGained+delta
        else data.unknownXPIntervals=data.unknownXPIntervals+1;self.lastXP=nil;return end
    end
    self.lastXP={level=level,xp=xp,maximum=maximum}
end
function R:TurnIn(id)
    local data=self:Data()
    if not data or not data.active or not V.Integer(id,1) or data.quests[id] then return end
    local count=0;for _ in pairs(data.quests) do count=count+1 end
    if count>=2048 then return end
    data.quests[id]=true;data.turnIns=data.turnIns+1
    self:Event(data,"turn-in","Quest "..id.." positively turned in during the run.")
end
function R:Observe(snapshot)
    local data=self:Data()
    if not data or not data.active or F.modules.ForeverAdapter.loading or type(snapshot)~="table"
       or type(snapshot.quests)~="table" or not V.Integer(snapshot.level,1) then return end
    data.samples=data.samples+1;data.lastLevel=snapshot.level
    self:Clock(data);self:XP(data)
    local zone=type(snapshot.character)=="table" and snapshot.character.zone
    if V.String(zone) then
        if self.lastZone and self.lastZone~=zone then data.zoneChanges=data.zoneChanges+1;self:Event(data,"zone",self.lastZone.." → "..zone) end
        self.lastZone=zone
    end
    for id in pairs(self.previousQuests or {}) do
        local q=snapshot.quests[id]
        if type(q)=="table" and q.turnedIn==true then self:TurnIn(id) end
    end
    self.previousQuests={}
    for id,q in pairs(snapshot.quests) do
        if type(q)=="table" and (q.accepted==true or q.complete==true) then self.previousQuests[id]=true end
    end
    local G=F.modules.GuideEngine
    local run=G.guide and F.modules.LevelingCampaign.runtime[G.guide.id]
    if run and run.state==G.state and run.snapshot==snapshot and not run.error then
        data.plan=run.route and run.route.plan.id or "level-aware pool"
        local step=G:Current()
        local decision=step and step.id or "target-reached"
        if decision~=self.lastDecision then
            data.decisions=data.decisions+1
            self:Event(data,"task",decision..(run.route and run.route.stage and (" · "..run.route.stage.title) or ""))
            self.lastDecision=decision
        end
        if run.status=="waiting" then
            local reason=run.route and run.route.reason or "eligibility"
            local key=data.plan..":"..snapshot.level..":"..reason
            if self.waitKey~=key then
                data.routeWaits=data.routeWaits+1;self.waitKey=key
                self:Event(data,"wait","No eligible route task at level "..snapshot.level.." ("..reason.."); includes prerequisite, failed-quest and defer restrictions.")
            end
        else self.waitKey=nil end
    end
end
function R:Start()
    if not F.character then return nil,"Character data unavailable." end
    if F.modules.Compatibility:Build().interface~=16001 then return nil,"Local run tracking requires interface 16001." end
    local old=F.character.routeRun
    if old then local valid,err=self:Validate(old);if not valid then return nil,err end end
    local snapshot=F.snapshot
    if type(snapshot)~="table" or type(snapshot.quests)~="table" or not V.Integer(snapshot.level,1) then return nil,"Wait for readable character and quest data." end
    if old and old.active then return true end
    if old then F.character.previousRouteRun=F.modules.SavedVariables.Copy(old) end
    local data={version=1,active=true,firstLevel=snapshot.level,lastLevel=snapshot.level,events={},quests={}}
    for _,key in ipairs(counters) do data[key]=0 end
    F.character.routeRun=data;self:Pause();self.owner=F.character;self:Observe(snapshot)
    return true
end
function R:Stop()
    local data,err=self:Data();if not data then return nil,err end
    if data.active then self:Clock(data);self:XP(data) end
    data.active=false;self:Pause();return true
end
function R:Lines()
    local data,err=self:Data();if not data then return nil,err end
    if data.active and not F.modules.ForeverAdapter.loading then self:Clock(data);self:XP(data) end
    local lines={"ForeverXP "..F.version.." · local run report · "..(data.active and "recording" or "stopped"),
        "Plan: "..tostring(data.plan or "not observed").." · levels "..data.firstLevel.." → "..data.lastLevel,
        "Observed online time: "..(data.clockAvailable and (math.floor(data.seconds/60).." min (includes idle time)") or "unavailable"),
        "Measured XP changes: "..data.xpGained.." · uncertain intervals: "..data.unknownXPIntervals.." · current XP readable: "..tostring(data.xpAvailable==true),
        "Unique observed turn-ins: "..data.turnIns.." · observed zone changes: "..data.zoneChanges,
        "Route waits: "..data.routeWaits.." · task changes: "..data.decisions.." · snapshots: "..data.samples}
    if data.xpAvailable and data.currentXPMax then lines[#lines+1]="XP to next level at last read: "..(data.currentXPMax-data.currentXP) end
    lines[#lines+1]="XP includes kills and other sources; waits do not prove an XP shortage. No XP reward or travel-time attribution is inferred."
    for i=math.max(1,#data.events-11),#data.events do lines[#lines+1]=data.events[i].kind..": "..data.events[i].text end
    return lines
end
function R:Report()
    local lines,err=self:Lines();if not lines then return nil,err end
    for _,line in ipairs(lines) do F:Print(line) end
    return true
end
function R:Initialize()
    if self.started then return end;self.started=true
    E:On("PLAYER_XP_UPDATE","route-run-xp",function(unit)
        if unit and unit~="player" then return end
        local data=R:Data()
        if data and data.active and not F.modules.ForeverAdapter.loading then R:Clock(data);R:XP(data) end
    end)
    E:On("QUEST_TURNED_IN","route-run-turnin",function(id) R:TurnIn(id) end)
    E:On("PLAYER_LEAVING_WORLD","route-run-loading",function()
        local data=R:Data();if data and data.active then R:Clock(data);if R.lastXP then data.unknownXPIntervals=data.unknownXPIntervals+1 end end
        R:Pause()
    end)
end
