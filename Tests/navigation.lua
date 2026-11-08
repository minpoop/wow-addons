local F,test,eq=...
local N,W,U=F.modules.Navigation,F.modules.Waypoints,F.modules.MainWindow
local names={"GetBuildInfo","C_Map","GetPlayerFacing","CreateVector2D","WorldMapFrame","InCombatLockdown","C_Timer","LibStub"}
local saved={}; for _,name in ipairs(names) do saved[name]=_G[name] end
local old={suspended=N.suspended,maps=N.maps,root=N.scannedRoot,lib=N.libraryScanned,pin=N.pin,pinRequested=N.pinRequested,waypoint=W.current,loading=F.modules.ForeverAdapter.loading,arrow=F.settings.arrow,pending=N.pending}
N.suspended=true; N.maps={}; N.scannedRoot=nil; N.libraryScanned=nil; N.pin=nil; N.pinRequested=false; N.pending=false
F.modules.ForeverAdapter.loading=false; F.settings.arrow=true
local current,shown,display,facing=990101,false,990101,0
local infos={ [990100]={mapID=990100,name="Synthetic root",parentMapID=0},[990101]={mapID=990101,name="Fixture Forest",parentMapID=990100},[990102]={mapID=990102,name="Fixture Coast",parentMapID=990100},[990103]={mapID=990103,name="Fixture Other Continent",parentMapID=990100} }
local function vector(x,y) return {GetXY=function() return x,y end} end
GetBuildInfo=function() return "fixture","fixture","fixture",16001 end
GetPlayerFacing=function() return facing end
C_Map={GetBestMapForUnit=function() return current end,GetMapInfo=function(id) return infos[id] end,
    GetPlayerMapPosition=function() return vector(.5,.5) end,GetMapWorldSize=function() return 1000,500 end,
    GetMapChildrenInfo=function() return {infos[990101],infos[990102],infos[990103]} end,
    OpenWorldMap=function(id) display=id;shown=true end}
local canvas=CreateFrame("Frame",nil,UIParent); canvas:SetWidth(1000);canvas:SetHeight(600)
WorldMapFrame={ScrollContainer={Child=canvas},IsShown=function() return shown end,GetMapID=function() return display end}
InCombatLockdown=function() return false end
C_Timer={After=function(_,fn) end}
LibStub=nil
local function target(zone,x,y)
    W:Set({zone=zone or "Fixture Forest",x=x or .6,y=y or .5,verification="reference-reviewed"}); N:Update(); return N.state
end
test("navigation derives cardinal bearings and player-relative rotation from real unit vectors",function()
    local east=N:Vector(100,0,0); eq(east.distance,100); eq(east.cardinal,"E"); assert(math.abs(east.rotation+math.pi/2)<1e-8)
    eq(N:Vector(0,100,0).cardinal,"N"); eq(N:Vector(0,-100,0).cardinal,"S"); eq(N:Vector(-100,0,0).cardinal,"W")
    assert(math.abs(N:Vector(100,0,3*math.pi/2).rotation)<1e-8)
    eq(N:Vector(0/0,0,0),nil)
end)
test("same-map navigation uses reported map dimensions rather than guessed zone scales",function()
    local state=target(); assert(math.abs(state.distance-100)<.001); eq(state.mapId,990101)
    eq(state.cardinal,"E")
    C_Map.GetMapWorldSize=function() return nil end
    state=target(); eq(state.distance,nil); assert(state.message:find("scale unavailable",1,true))
    C_Map.GetMapWorldSize=function() return 1000,500 end
end)
test("cross-map world coordinates require a shared instance and preserve axis orientation",function()
    CreateVector2D=function(x,y) return {x=x,y=y} end
    C_Map.GetWorldPosFromMapPos=function(id,v)
        local offset=id==990102 and 1000 or 0
        return id==990103 and 1 or 0,vector(-v.y*500,-(v.x*1000+offset))
    end
    local state=target("Fixture Coast",.1,.5); assert(math.abs(state.distance-600)<.001);eq(state.cardinal,"E")
    state=target("Fixture Other Continent",.1,.5); eq(state.distance,nil);eq(state.mapId,990103)
    C_Map.GetWorldPosFromMapPos=nil;CreateVector2D=nil
end)
test("unknown facing, unsupported maps and temporary API failures retain coordinates",function()
    GetPlayerFacing=function() return nil end
    local state=target();eq(state.rotation,nil);assert(state.distance)
    state=target("Unmatched map");eq(state.mapId,nil);eq(state.distance,nil)
    local getter=C_Map.GetPlayerMapPosition
    C_Map.GetPlayerMapPosition=function() error("loading") end
    state=target();eq(state.distance,nil);assert(state.message:find("position unavailable",1,true))
    C_Map.GetPlayerMapPosition=getter;GetPlayerFacing=function() return facing end
end)
test("ambiguous map names are never cached as a guessed destination",function()
    N:Remember(990200,{name="Duplicate fixture"});N:Remember(990201,{name="Duplicate fixture"});N:Remember(990200,{name="Duplicate fixture"})
    eq(N.maps.duplicatefixture,false)
    N:Remember(990201,{name="Fixture Forest"})
    eq(N:Resolve("Fixture Forest",990101),nil)
    N.maps.fixtureforest=990101
end)
test("world-map action uses safe opening, places a canvas pin, and refuses combat",function()
    target();assert(N:ShowMap());eq(display,990101);eq(shown,true);eq(N.pin:IsShown(),true)
    assert(math.abs(N.pin.SetPointArgs[4]-600)<.001);eq(N.pin.SetPointArgs[5],-300)
    display=990102;N:UpdatePin();eq(N.pin:IsShown(),false)
    display=990101;InCombatLockdown=function() return true end
    eq(N:ShowMap(),nil);InCombatLockdown=function() return false end
    W:Set(nil);eq(N.pin:IsShown(),false)
end)
test("optional HereBeDragons data supports navigation without a direct map-position getter",function()
    local map=C_Map;C_Map=nil;N.maps={};N.libraryScanned=nil
    local lib={GetPlayerZonePosition=function() return .5,.5,990101 end,GetAllMapIDs=function() return {990101,990102} end,
        GetLocalizedMap=function(_,id) return infos[id].name end,
        GetWorldCoordinatesFromZone=function(_,x,y,id) return -(x*1000+(id==990102 and 1000 or 0)),-y*500,0 end}
    LibStub={GetLibrary=function() return lib end}
    local state=target("Fixture Coast",.1,.5);assert(math.abs(state.distance-600)<.001);eq(state.cardinal,"E")
    LibStub=nil;C_Map=map;N.maps={};N.scannedRoot=nil;N.libraryScanned=nil
end)
test("navigation ticks coalesce and stop when the addon and map are hidden",function()
    target();shown=false;U:Show("guide");N.suspended=false
    local queue={};C_Timer.After=function(_,fn) queue[#queue+1]=fn end
    N.pending=false;N:EnsureTick();N:EnsureTick();eq(#queue,1)
    U.frame:Hide();queue[1]();eq(#queue,1);eq(N.pending,false)
    N.suspended=true;U:Show("guide")
end)
test("unsupported interfaces and loading screens never show a stale direction",function()
    target();assert(N.state.distance)
    local build=GetBuildInfo;GetBuildInfo=function() return "other","other","other",999999 end
    N:Update();eq(N.state.distance,nil);eq(N.state.rotation,nil)
    GetBuildInfo=build;F.modules.ForeverAdapter.loading=true
    N:Update();eq(N.state.distance,nil);eq(N:Active(),false)
    F.modules.ForeverAdapter.loading=false;target();assert(N.state.rotation)
    F.modules.Events:Emit("PLAYER_LEAVING_WORLD")
    eq(N.state.rotation,nil);eq(U.navArrow:IsShown(),false);eq(N.pin:IsShown(),false)
end)
for _,name in ipairs(names) do _G[name]=saved[name] end
if N.pin then N.pin:Hide() end
N.maps,N.scannedRoot,N.libraryScanned,N.pin,N.pinRequested,N.suspended,N.pending=old.maps,old.root,old.lib,old.pin,old.pinRequested,old.suspended,old.pending
F.modules.ForeverAdapter.loading=old.loading;F.settings.arrow=old.arrow
W.current=old.waypoint;N:Update()
