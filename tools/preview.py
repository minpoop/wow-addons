"""Render UI source with mocked frames. Previews are not in-game screenshots."""
from html import escape
import base64
import json
from pathlib import Path
import subprocess
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'dist/previews'
OUTPUT.mkdir(parents=True, exist_ok=True)
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
local objects, methods = {}, {}
local function object(kind,parent,layer)
    local item = setmetatable({id=#objects+1,kind=kind,parent=parent,layer=layer,shown=true}, {__index=methods})
    objects[#objects+1] = item
    return item
end
for _,name in ipairs({"SetFrameStrata","SetMovable","EnableMouse","SetClampedToScreen","RegisterForDrag","StartMoving","StopMovingOrSizing","RegisterEvent","UnregisterEvent","SetJustifyH"}) do methods[name]=function() end end
function methods:SetWidth(v) self.width=v end
function methods:SetHeight(v) self.height=v end
function methods:SetScale(v) self.scale=v end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetPoint(point,relative,relativePoint,x,y) self.point=point;self.relative=relative;self.relativePoint=relativePoint;self.x=x;self.y=y end
function methods:ClearAllPoints() self.point=nil;self.all=nil end
function methods:SetAllPoints(relative) self.all=relative end
function methods:SetText(value) self.text=value end
function methods:SetFont(_,size) self.fontSize=size end
function methods:SetFontObject() self.fontSize=12 end
function methods:SetColorTexture(...) self.color={...} end
function methods:SetTexture(value,...) if type(value)=="string" then self.texture=value else self.color={value,...} end end
function methods:SetTextColor(...) self.color={...} end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:IsShown() return self.shown end
function methods:SetScript() end
function methods:CreateTexture(_,layer) return object("Texture",self,layer) end
function methods:CreateFontString(_,layer) return object("FontString",self,layer) end
UIParent=object("Root"); UIParent.width=640;UIParent.height=500
function CreateFrame(kind,_,parent) return object(kind,parent) end
SlashCmdList={}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
function UnitGUID() return "preview-only-character" end
function PreviewSnapshot()
    local result={}
    for i,node in ipairs(objects) do
        result[i]={id=node.id,kind=node.kind,parent=node.parent and node.parent.id,layer=node.layer,
            width=node.width,height=node.height,scale=node.scale,alpha=node.alpha,point=node.point,
            relative=node.relative and node.relative.id,relativePoint=node.relativePoint,x=node.x,y=node.y,
            all=node.all and node.all.id,text=node.text,fontSize=node.fontSize,color=node.color,texture=node.texture,shown=node.shown}
    end
    return result
end
''')
for line in (ROOT / 'ForeverXP/ForeverXP.toc').read_text().splitlines():
    if line.endswith('.lua'):
        lua.execute((ROOT / 'ForeverXP' / line).read_text())
lua.execute('ForeverXP:Initialize(); ForeverXP.settings.opacity=1')
# Explicit synthetic layout data, never registered or packaged as playable guides.
lua.execute('''
local F=ForeverXP
local engine=F.modules.GuideEngine
engine.guide={title="A road through the mist · layout sample",steps={
    {id="one",text="Review your route."},
    {id="two",text="Check your supplies before moving on."},
    {id="three",text="Continue when you are ready."}}}
engine.index=2;engine.state={completed={one=true},overrides={}}
F.modules.Waypoints.current={zone="Sample map",x=0.42,y=0.58}
local catalog={id="sample",profession="sample",title="Supply ledger · layout sample",minSkill=0,maxSkill=10,
    recipes={sample={output="Sample craft",outputCount=1,inputs={["Sample ore"]=2,["Sample reagent"]=1}}},
    producers={},segments={{id="sample",from=0,to=10,trainer="Review the next training requirement.",choices={{recipe="sample",chance=1,gain=1}}}}}
local state={mode="Hybrid",target=7,safety=0.2,prices={["Sample reagent"]=2}}
local controller=F.modules.ProfessionController
controller.catalog=catalog;controller.state=state
controller.plan=assert(F.modules.ProfessionPlanner:Plan(catalog,state,3,{["Sample ore"]=3,["Sample reagent"]=1},{sample=true},state.prices,{["Sample ore"]={verified=true,route="preview-only"}}))
''')


def snapshot():
    result = {}
    for row in lua.globals().PreviewSnapshot().values():
        value = dict(row.items())
        if 'color' in value:
            value['color'] = list(value['color'].values())
        result[value['id']] = value
    return result


def render(nodes):
    geometry = {}

    def bounds(key):
        if key in geometry:
            return geometry[key]
        node = nodes[key]
        if node.get('all'):
            value = bounds(node['all'])
        else:
            width = node.get('width', 0)
            height = node.get('height', max(1, len(node.get('text', '').splitlines())) * 14)
            x = y = 0
            if node.get('relative'):
                rx, ry, rw, rh = bounds(node['relative'])
                px, py = (0.5, 0.5) if node.get('point') == 'CENTER' else (0, 0)
                ax, ay = (0.5, 0.5) if node.get('relativePoint') == 'CENTER' else (0, 0)
                x = rx + rw * ax + node.get('x', 0) - width * px
                y = ry + rh * ay - node.get('y', 0) - height * py
            value = x, y, width, height
        geometry[key] = value
        return value

    children = {}
    for key, node in nodes.items():
        children.setdefault(node.get('parent'), []).append(key)
    layers = {'BACKGROUND': 0, 'BORDER': 1, 'ARTWORK': 2, 'OVERLAY': 3}

    def paint(key):
        node = nodes[key]
        if not node['shown']:
            return ''
        x, y, width, height = bounds(key)
        output = ''
        if node['kind'] in ('Texture', 'FontString'):
            color = node.get('color', [1, 1, 1, 1])
            color += [1] * (4-len(color))
            rgba = f'rgba({round(color[0]*255)},{round(color[1]*255)},{round(color[2]*255)},{color[3]})'
            style = f'left:{x}px;top:{y}px;width:{width}px;height:{height}px;'
            if node['kind'] == 'Texture':
                if node.get('texture'):
                    relative = node['texture'].replace('\\', '/').removeprefix('Interface/AddOns/')
                    path = ROOT / relative
                    path.resolve().relative_to((ROOT/'ForeverXP').resolve())
                    png = subprocess.check_output(['magick',str(path),'png:-'])
                    url = 'data:image/png;base64,' + base64.b64encode(png).decode()
                    output = f'<img class="texture" alt="James Sunderland portrait" src="{url}" style="{style}">'
                else:
                    output = f'<div class="texture" style="{style}background:{rgba}"></div>'
            else:
                text = escape(node.get('text', ''))
                output = f'<div class="label" style="{style}color:{rgba};font-size:{node.get("fontSize",12)}px">{text}</div>'
        for child in sorted(children.get(key, []), key=lambda item: (4 if nodes[item]['kind'] in ('Frame', 'Button') else layers.get(nodes[item].get('layer'), 0), item)):
            output += paint(child)
        return output

    return paint(1)


for view, theme, title in [('guide', 'fog', '01 / ROUTE JOURNAL'),
                           ('professions', 'fog', '02 / SUPPLY LEDGER'),
                           ('settings', 'contrast', '03 / HIGH-CONTRAST OPTIONS'),
                           ('elwynn', 'fog', '04 / ELWYNN SHARED REFERENCE ROUTE'),
                           ('leveling', 'fog', '05 / LEVEL-AWARE ALLIANCE 1–20')]:
    if view == 'elwynn':
        lua.execute('ForeverXP.settings.theme="fog"; ForeverXP:Command("elwynn")')
    elif view == 'leveling':
        lua.execute('''
            local F=ForeverXP
            F.settings.theme="fog"
            assert(F.modules.GuideEngine:Select(F.modules.LevelingCampaign.id,F.character))
            F.snapshot={level=14,active={},quests={},character={zone="Elwynn Forest"}}
            F.modules.GuideEngine:Update(F.snapshot)
            F.modules.MainWindow:Show("guide")
        ''')
    else:
        lua.execute(f'ForeverXP.settings.theme={json.dumps(theme)}; ForeverXP.modules.MainWindow:Show({json.dumps(view)})')
    nodes = snapshot()
    assert any('James Sunderland' in row.get('text', '') for row in nodes.values())
    content = render(nodes)
    data_label = 'Classic reference content · live validation pending' if view in ('elwynn', 'leveling') else 'synthetic layout data'
    html = f'''<!doctype html><html><head><meta charset="utf-8"><style>
    *{{box-sizing:border-box}}body{{margin:0;background:#171e1a;color:#c9cec2;width:1000px;height:820px;font-family:Arial,sans-serif}}
    h1{{position:absolute;left:62px;top:30px;font-size:15px;letter-spacing:3px;font-weight:400}}
    .stamp{{position:absolute;right:62px;top:43px;font-size:10px;letter-spacing:2px;color:#92a08e}}
    .scene{{position:absolute;left:84px;top:88px;width:640px;height:500px;transform:scale(1.3);transform-origin:top left}}
    .texture,.label{{position:absolute}}.label{{font-family:Georgia,serif;line-height:14px;white-space:pre-wrap;overflow:hidden}}
    footer{{position:absolute;left:62px;bottom:45px;font-size:11px;line-height:19px;color:#94a18f;letter-spacing:.4px}}
    </style></head><body><h1>FOREVER XP — {title}</h1><div class="stamp">SOURCE-RENDERED PREVIEW</div>
    <div class="scene">{content}</div><footer>Mocked client · {data_label} · not captured in WoW<br>Actual game fonts, wrapping and rendering may differ.</footer></body></html>'''
    (OUTPUT / f'{view}.html').write_text(html)
print(OUTPUT)
