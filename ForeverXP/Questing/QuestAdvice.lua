local F=ForeverXP
local A=F:Register("QuestAdvice",{records={}})
local V=F.modules.Validation
local kinds={collect=true,kill=true,explore=true,delivery=true,other=true}
function A:RegisterReference(records)
    if type(records)~="table" or not V.DataOnly(records) then return nil,"Advice must contain finite data only." end
    local count=0
    for id,record in pairs(records) do
        count=count+1
        if count>2048 or not V.Integer(id,1) or type(record)~="table" or not V.String(record.title)
           or not V.Integer(record.questLevel,1) or not kinds[record.kind] then return nil,"Invalid quest advice record." end
        for _,key in ipairs({"optional","escort","event","cave"}) do
            if record[key]~=nil and type(record[key])~="boolean" then return nil,"Invalid advice flag." end
        end
        for _,key in ipairs({"eliteTarget","eliteSource"}) do
            if record[key]~=nil and not V.String(record[key]) then return nil,"Invalid reference target." end
        end
        if record.tips~=nil then
            if not V.Array(record.tips,true) or #record.tips>3 then return nil,"Invalid quest tips." end
            for _,tip in ipairs(record.tips) do if not V.String(tip) or #tip>400 then return nil,"Invalid quest tip." end end
        end
    end
    self.records=F.modules.SavedVariables.Copy(records)
    return true
end
local function objectiveKind(quest)
    for _,row in ipairs(type(quest.objectives)=="table" and quest.objectives or {}) do
        if type(row)=="table" then
            if row.type=="item" then return "collect" elseif row.type=="monster" then return "kill" end
        end
    end
end
function A:For(step,snapshot)
    local result={warnings={},tips={}}
    if type(step)~="table" or not V.Integer(step.questId,1) then return result end
    local phase=step.type
    if phase~="ACCEPT_QUEST" and phase~="COMPLETE_QUEST" and phase~="TURN_IN_QUEST" then return result end
    snapshot=type(snapshot)=="table" and snapshot or {}
    if F.modules.ForeverAdapter.loading then snapshot={} end
    local quest=type(snapshot.quests)=="table" and snapshot.quests[step.questId] or nil
    quest=type(quest)=="table" and quest or {}
    local record=self.records[step.questId] or {}
    local settings=F.settings or {}
    local function warn(code,badge,text,severity)
        if settings.questWarnings==false then return end
        local warning={code=code,badge=badge,text=text,severity=severity or "caution"}
        result.warnings[#result.warnings+1]=warning
        if not result.severity or (warning.severity=="danger" and result.severity~="danger") then
            result.badge,result.severity=badge,warning.severity
        end
    end
    local function tip(text)
        if settings.questTips~=false and #result.tips<2 then result.tips[#result.tips+1]=text end
    end
    if quest.failed==true then
        warn("failed","QUEST FAILED","Your quest log marks this quest failed. Check the log before attempting it again.","danger")
        return result
    end
    if quest.turnedIn==true then return result end
    if phase=="TURN_IN_QUEST" or quest.complete==true then
        tip("Check the quest-log recipient and turn in any required items. Completed objectives do not prove the quest was turned in.")
        return result
    end
    local tag=quest.tagId
    if tag==62 then warn("raid","RAID QUEST","Live quest tag: raid encounter. Arrange a suitable group before attempting it.")
    elseif tag==81 then warn("dungeon","DUNGEON QUEST","Live quest tag: dungeon. Check instance access and bring a suitable group.")
    elseif tag==41 then warn("pvp","PVP QUEST","Live quest tag: PvP. Expect opposing players and check the objective before proceeding.")
    elseif tag==1 or quest.isElite==true then
        warn("group","ELITE / GROUP","Live quest tag indicates elite or group content. Check the target and bring help as needed.")
    elseif record.eliteTarget then
        warn("elite","ELITE TARGET","Reference: "..record.eliteTarget.." is an elite target. Check its actual level and consider bringing help.")
    elseif record.eliteSource then
        warn("elite-source","ELITE LOOT SOURCE","Reference loot lead: "..record.eliteSource.." is elite. Check the target and possible alternative sources before engaging.")
    end
    local questLevel=V.Integer(quest.level,1) and quest.level or (V.Integer(step.questLevel,1) and step.questLevel or record.questLevel)
    if V.Integer(snapshot.level,1) and V.Integer(questLevel,1) then
        local difference=questLevel-snapshot.level
        if difference>=2 then
            local source=V.Integer(quest.level,1) and "Live quest level" or "Reference quest level"
            warn("level","QUEST +"..difference.." LEVELS",source.." "..questLevel.." is "..difference.." above you. Consider gaining levels or bringing help.",difference>=4 and "danger" or "caution")
        end
    end
    if record.escort then
        warn("escort","ESCORT EVENT","Reference: escort objective. Prepare first and stay near the escort until the objective is credited.")
    elseif record.event then
        warn("event","SCRIPTED EVENT","Reference: this objective needs an event. Prepare before triggering it and watch for success or failure in the quest log.")
    end
    if record.cave then warn("cave","CLOSE QUARTERS","Reference terrain note: tight passages can make extra pulls and returning enemies harder to avoid. Keep a retreat clear.") end
    if #result.warnings==0 and (record.optional or step.optional) then
        warn("optional","OPTIONAL QUEST","Optional reference content: check the quest's difficulty and special requirements before committing.")
    end
    for _,text in ipairs(record.tips or {}) do tip("Reference tip: "..text) end
    if #result.tips==0 then
        local kind=record.kind or objectiveKind(quest)
        if kind=="collect" then tip("Check the required item names and carried quest counts before farming. Kill credit alone does not satisfy an item objective.")
        elseif kind=="kill" then tip("Confirm the named targets in the quest log. Pull carefully and leave room to retreat.")
        elseif kind=="explore" then tip("Reach the named area and wait for exploration credit before returning. The reference marker is a lead to check in game.")
        elseif kind=="delivery" then tip("Check the named recipient and carry any required quest item before travelling.") end
    end
    return result
end
function A:Text(advice)
    local lines={}
    for _,warning in ipairs(advice.warnings) do lines[#lines+1]="WARNING: "..warning.text end
    for _,tip in ipairs(advice.tips) do
        local reference=tip:match("^Reference tip: (.*)$")
        lines[#lines+1]=reference and ("TIP (REFERENCE): "..reference) or ("TIP: "..tip)
    end
    return table.concat(lines,"\n\n")
end
