"""Compare real planner decisions on an explicitly synthetic three-quest map."""
import argparse
import json
from pathlib import Path
from lupa.lua51 import LuaRuntime

ROOT=Path(__file__).resolve().parents[1]


def benchmark():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute('print=function() end')
    for line in (ROOT/'ForeverXP/ForeverXP.toc').read_text().splitlines():
        if line.endswith('.lua'):lua.execute((ROOT/'ForeverXP'/line).read_text())
    lua.execute('''
        local F=ForeverXP
        F.settings=F.modules.Settings:Load({}); F.db={settings=F.settings}
        local G,P=F.modules.GuideEngine,F.modules.RoutePlanner
        local guide={id="batch-benchmark-fixture",title="Synthetic hub benchmark",faction="Alliance",
            source="Synthetic offline geometry; not server content",verification="reference-reviewed",
            campaign={targetLevel=20,maxQuestLag=3,maxQuestLead=2},steps={}}
        local ids={990601,990602,990603}
        for n,id in ipairs(ids) do
            for _,phase in ipairs({"accept","work","turn-in"}) do
                local kind=({accept="ACCEPT_QUEST",work="COMPLETE_QUEST",["turn-in"]="TURN_IN_QUEST"})[phase]
                guide.steps[#guide.steps+1]={id=id.."-"..phase,type=kind,questId=id,questTitle="Synthetic "..n,
                    questLevel=7,minLevel=1,text="Synthetic task",zone="Synthetic fields",
                    waypoint={zone="Synthetic fields",x=phase=="work" and .8 or .1,y=phase=="work" and (.3+n*.05) or .5}}
            end
        end
        guide.steps[#guide.steps+1]={id="goal",type="REACH_LEVEL",level=20,text="Synthetic level goal"}
        assert(G:RegisterReferenceGuide(guide))
        assert(P:Register({id="benchmark-fixture",title="Synthetic batches",faction="Alliance",minLevel=1,maxLevel=19,
            source="Synthetic offline benchmark",verification="reference-planned",guides={guide.id},zones={"Synthetic fields"},
            pickupLead=5,reservedSlots=3,stages={
                {id="a",title="Synthetic pickups",phase="accept",quests=ids,maxLevel=19},
                {id="w",title="Synthetic field work",phase="work",quests=ids,maxLevel=19},
                {id="t",title="Synthetic returns",phase="turn-in",quests=ids,maxLevel=19}}}))
        function BenchmarkRun(mode)
            F.settings.routePlan=mode
            F.character={guides={},professions={},windows={}}; assert(G:Select(guide.id,F.character))
            local s={level=6,quests={},character={zone="Synthetic fields",faction="Alliance"}}
            local result={distance=0,crossings=0,actions={}}
            local x,y,atHub=.1,.5,true
            for _=1,9 do
                G:Update(s)
                local step=assert(G:Current());local id=assert(step.questId)
                local target=step.waypoint
                local hub=step.type~="COMPLETE_QUEST"
                if hub~=atHub then result.crossings=result.crossings+1 end;atHub=hub
                result.distance=result.distance+math.sqrt((target.x-x)^2+(target.y-y)^2);x,y=target.x,target.y
                result.actions[#result.actions+1]=step.type..":"..id
                if step.type=="ACCEPT_QUEST" then s.quests[id]={accepted=true}
                elseif step.type=="COMPLETE_QUEST" then s.quests[id].complete=true
                else s.quests[id]={turnedIn=true} end
                s.trackedQuestId=id
            end
            G:Update(s)
            assert(G.state.campaign.status=="waiting")
            return result
        end
    ''')
    result={'scope':'Synthetic three-quest geometry only; not measured Forever travel, time or XP.'}
    for name,mode in [('quest_pool','off'),('phase_batches','auto')]:
        value=lua.globals().BenchmarkRun(mode)
        result[name]={'hub_crossings':value.crossings,'map_units':round(value.distance,6),'actions':list(value.actions.values())}
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path)
    parser.add_argument('--check',type=Path)
    args=parser.parse_args()
    report=benchmark()
    text=json.dumps(report,indent=2)+'\n'
    if args.check:
        if json.loads(args.check.read_text())!=report:raise SystemExit('Synthetic route benchmark changed')
        print('Synthetic route benchmark matches actual planner decisions')
    elif args.output:args.output.write_text(text);print(args.output)
    else:print(text,end='')
