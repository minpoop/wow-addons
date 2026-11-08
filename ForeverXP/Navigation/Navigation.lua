local F=ForeverXP
local N=F:Register("Navigation",{maps={},state={message="Coordinates"},source="Questie/Questie@97d7518d5402d185e47b39522a6ea09b8316f0ef"})
local V,C,E=F.modules.Validation,F.modules.Compatibility,F.modules.Events
local PI2=math.pi*2
local function call(owner,name,...)
    if type(owner)~="table" or type(owner[name])~="function" then return nil end
    local ok,a,b,c,d=pcall(owner[name],...); if ok then return a,b,c,d end
end
local function method(owner,name,...) return call(owner,name,owner,...) end
local function normalized(name) return type(name)=="string" and name:lower():gsub("[%p%s]","") or nil end
local function xy(vector)
    if type(vector)~="table" and type(vector)~="userdata" then return end
    local ok,x,y=pcall(function() return vector:GetXY() end)
    if ok and V.Finite(x) and V.Finite(y) then return x,y end
end
local function point(x,y) return V.Finite(x) and V.Finite(y) and x>=0 and x<=1 and y>=0 and y<=1 end
local function atan2(y,x)
    if math.atan2 then return math.atan2(y,x) end
    if x>0 then return math.atan(y/x) end
    if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
    if y>0 then return math.pi/2 elseif y<0 then return -math.pi/2 end
    return 0
end
function N:Vector(east,north,facing)
    if not V.Finite(east) or not V.Finite(north) then return nil end
    local distance=math.sqrt(east*east+north*north)
    local bearing=atan2(east,north)%PI2
    local names={"N","NE","E","SE","S","SW","W","NW"}
    return {distance=distance,bearing=bearing,rotation=V.Finite(facing) and -((bearing+facing)%PI2) or nil,
        cardinal=names[math.floor(bearing/(math.pi/4)+0.5)%8+1],message=distance<8 and "Near target" or "Straight-line guidance"}
end
function N:Library()
    if type(LibStub)=="table" and type(LibStub.GetLibrary)=="function" then
        local ok,lib=pcall(LibStub.GetLibrary,LibStub,"HereBeDragons-2.0",true)
        if ok and type(lib)=="table" then return lib end
    end
end
function N:Remember(id,info)
    if V.Integer(id,1) and type(info)=="table" and V.String(info.name) then
        local key=normalized(info.name)
        -- Duplicate/localized names are ambiguous; do not choose an arbitrary map.
        if self.maps[key]==false then return end
        if self.maps[key] and self.maps[key]~=id then self.maps[key]=false else self.maps[key]=id end
    end
end
function N:Resolve(zone,current)
    local key=normalized(zone)
    if not key then return nil end
    local info=call(C_Map,"GetMapInfo",current)
    self:Remember(current,info)
    local lib=self:Library()
    if lib and not self.libraryScanned then
        local ids=method(lib,"GetAllMapIDs")
        if V.Array(ids) and #ids<=4096 then
            for _,id in ipairs(ids) do self:Remember(id,{name=method(lib,"GetLocalizedMap",id)}) end
            self.libraryScanned=true
        end
    end
    local root=current; local seen={}
    for _=1,12 do
        if not V.Integer(root,1) or seen[root] then break end
        seen[root]=true; local parent=call(C_Map,"GetMapInfo",root)
        self:Remember(root,parent)
        if not parent or not V.Integer(parent.parentMapID,1) then break end
        root=parent.parentMapID
    end
    if root and self.scannedRoot~=root then
        local children=call(C_Map,"GetMapChildrenInfo",root,nil,true)
        if V.Array(children) and #children<=4096 then
            for _,child in ipairs(children) do if type(child)=="table" then self:Remember(child.mapID,child) end end
            self.scannedRoot=root
        end
    end
    return self.maps[key] or nil
end
function N:Player()
    local lib=self:Library()
    if lib then
        local x,y,map=method(lib,"GetPlayerZonePosition")
        if point(x,y) and V.Integer(map,1) then return x,y,map,lib end
    end
    local map=call(C_Map,"GetBestMapForUnit","player")
    if not V.Integer(map,1) then return nil end
    local x,y=xy(call(C_Map,"GetPlayerMapPosition",map,"player"))
    if point(x,y) then return x,y,map end
end
function N:World(map,x,y)
    if type(CreateVector2D)~="function" then return end
    local ok,vector=pcall(CreateVector2D,x,y); if not ok then return end
    local instance,position=call(C_Map,"GetWorldPosFromMapPos",map,vector)
    local north,west=xy(position)
    if V.Integer(instance) and V.Finite(north) and V.Finite(west) then return -west,north,instance end
end
function N:Read()
    local w=F.modules.Waypoints.current
    if not w or not F.settings.waypoints then return {message="No target"} end
    if C:Build().interface~=16001 or F.modules.ForeverAdapter.loading then return {message="Coordinates · direction unavailable"} end
    local x,y,map,lib=self:Player()
    local current=map or call(C_Map,"GetBestMapForUnit","player")
    local target=self:Resolve(w.zone,current)
    local state={mapId=target,message=target and "Travel to target zone" or "Map identity unavailable"}
    if not x then state.message="Player position unavailable · coordinates"; return state end
    if not target then return state end
    local east,north
    if lib then
        local sx,sy,si=method(lib,"GetWorldCoordinatesFromZone",x,y,map)
        local tx,ty,ti=method(lib,"GetWorldCoordinatesFromZone",w.x,w.y,target)
        if V.Finite(sx) and V.Finite(sy) and V.Finite(tx) and V.Finite(ty) and V.Integer(si) and si==ti then east,north=sx-tx,ty-sy end
    end
    if not east then
        local sx,sy,si=self:World(map,x,y); local tx,ty,ti=self:World(target,w.x,w.y)
        if sx and tx and si==ti then east,north=tx-sx,ty-sy end
    end
    if not east and map==target then
        local width,height=call(C_Map,"GetMapWorldSize",map)
        if V.Finite(width) and V.Finite(height) and width>0 and height>0 and width<100000 and height<100000 then east,north=(w.x-x)*width,(y-w.y)*height end
    end
    if east then
        local facing=F.settings.arrow and call(_G,"GetPlayerFacing") or nil
        local vector=self:Vector(east,north,facing)
        if vector then vector.mapId=target; return vector end
    end
    if map==target then state.message="Map scale unavailable · coordinates" end
    return state
end
function N:Update()
    local ok,state=pcall(self.Read,self)
    self.state=ok and state or {message="Coordinates · navigation temporarily unavailable"}
    self:UpdatePin()
    if F.modules.MainWindow.frame then F.modules.MainWindow:RenderNavigation() end
end
function N:Active()
    local U=F.modules.MainWindow
    return not self.suspended and not F.modules.ForeverAdapter.loading and F.settings and F.settings.waypoints and F.modules.Waypoints.current
        and C:Build().interface==16001 and ((U.frame and U.frame:IsShown() and U.tab=="guide") or (self.pinRequested and method(WorldMapFrame,"IsShown")))
        and (self:Library() or (type(C_Map)=="table" and type(C_Map.GetPlayerMapPosition)=="function"))
end
function N:EnsureTick()
    if self.pending or not self:Active() or type(C_Timer)~="table" or type(C_Timer.After)~="function" then return end
    self.pending=true
    local ok=pcall(C_Timer.After,F.settings.navigationInterval,function()
        N.pending=false
        if N:Active() then N:Update(); N:EnsureTick() end
    end)
    if not ok then self.pending=false end
end
function N:UpdatePin()
    if self.pin then self.pin:Hide() end
    local w=F.modules.Waypoints.current
    if not w or not F.settings.waypoints or not self.pinRequested or not method(WorldMapFrame,"IsShown") then return end
    local map=method(WorldMapFrame,"GetMapID")
    if not map or map~=self.state.mapId then return end
    local canvas=WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
    if not canvas then return end
    local width,height=method(canvas,"GetWidth"),method(canvas,"GetHeight")
    if not V.Finite(width) or not V.Finite(height) or width<=0 or height<=0 then return end
    if not self.pin then
        self.pin=CreateFrame("Frame",nil,canvas); self.pin:SetWidth(16); self.pin:SetHeight(16)
        local level=method(canvas,"GetFrameLevel")
        if V.Finite(level) then self.pin:SetFrameLevel(level+10) end
        self.pin.dot=self.pin:CreateTexture(nil,"ARTWORK"); self.pin.dot:SetAllPoints(self.pin)
        self.pin.label=self.pin:CreateFontString(nil,"OVERLAY"); self.pin.label:SetFont("Fonts\\FRIZQT__.TTF",11)
        self.pin.label:SetPoint("TOPLEFT",self.pin,"BOTTOMLEFT",0,-2); self.pin.label:SetText("ForeverXP")
    end
    if self.pin.SetParent then self.pin:SetParent(canvas) end
    self.pin:ClearAllPoints(); self.pin:SetPoint("CENTER",canvas,"TOPLEFT",w.x*width,-w.y*height)
    F.modules.Themes:Texture(self.pin.dot,F.modules.Themes:Get().progress)
    F.modules.Themes:Text(self.pin.label,F.modules.Themes:Get().accent)
    self.pin:Show()
end
function N:ShowMap()
    local w=F.modules.Waypoints.current
    if not w then return nil,"No navigation target is selected." end
    if C:Build().interface~=16001 then return nil,"Map guidance is unavailable on this interface; use the displayed coordinates." end
    if type(InCombatLockdown)~="function" or call(_G,"InCombatLockdown")~=false then return nil,"Open the target map after combat." end
    self:Update()
    if not self.state.mapId then return nil,"Target map could not be matched; use the displayed zone and coordinates." end
    if type(C_Map)~="table" or type(C_Map.OpenWorldMap)~="function" then return nil,"Open your world map manually; this client lacks safe map opening." end
    local ok,err=pcall(C_Map.OpenWorldMap,self.state.mapId)
    if not ok then return nil,"World map could not be opened: "..tostring(err) end
    self.pinRequested=true; self:UpdatePin(); self:EnsureTick()
    if type(C_Timer)=="table" and type(C_Timer.After)=="function" then pcall(C_Timer.After,0,function() N:UpdatePin() end) end
    return true
end
function N:Start()
    if self.started then return end; self.started=true
    E:On("FXP_CHANGED","navigation",function() N:Update(); N:EnsureTick() end)
    E:On("ZONE_CHANGED_NEW_AREA","navigation-map",function() N.scannedRoot=nil; N:Update() end)
    E:On("WORLD_MAP_OPEN","navigation-pin",function() N:UpdatePin(); N:EnsureTick() end)
    E:On("PLAYER_LEAVING_WORLD","navigation-loading",function()
        N.state={message="Coordinates · loading"}
        if N.pin then N.pin:Hide() end
        if F.modules.MainWindow.frame then F.modules.MainWindow:RenderNavigation() end
    end)
end
