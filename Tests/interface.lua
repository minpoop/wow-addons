local F,test,eq=...
local U,M,S,G=F.modules.MainWindow,F.modules.ContextMenu,F.modules.Settings,F.modules.GuideEngine
local old={character=F.character,tab=U.tab,width=U.width,height=U.height,compact=F.settings.compact,font=F.settings.fontSize,locked=F.settings.locked,theme=F.settings.theme,guide=G.guide,index=G.index,state=G.state}
local oldController={catalog=F.modules.ProfessionController.catalog,state=F.modules.ProfessionController.state,plan=F.modules.ProfessionController.plan}
F.character={guides={},professions={},windows={}}
F.settings.compact=false; F.settings.locked=false
U:Show("guide")
test("resizing clamps bounds, reflows the reading card and persists size per character",function()
    assert(U:ResizeTo(800,560,true)); eq(U.width,800); eq(U.height,560)
    eq(U.contentWidth,724); eq(F.character.windows.main.width,800); eq(F.character.windows.main.height,560)
    U.frame.scripts.OnSizeChanged(U.frame,2000,100)
    eq(U.width,980); eq(U.height,260)
    U.resizeGrip.scripts.OnMouseUp(); eq(F.character.windows.main.width,980)
    local first=F.character
    F.character={guides={},professions={},windows={}}; U:RestorePosition(); eq(U.width,620); eq(U.height,420)
    F.character=first; U:RestorePosition(); eq(U.width,980); eq(U.height,260)
    eq(U:ResizeTo(0/0,400,true),nil)
    U:ResizeTo(620,420,true)
end)
test("every window action is hidden until the right-click menu opens",function()
    eq(U.buttons,nil); eq(U.previous,nil); eq(U.recipeControls,nil); eq(U.themeControls,nil)
    U.frame.scripts.OnMouseUp(U.frame,"RightButton"); eq(M.frame:IsShown(),true); eq(M.overlay:IsShown(),true)
    assert(M:Invoke("themes")); eq(M.page,"themes")
    assert(M:Invoke("theme-warcraft")); eq(F.settings.theme,"warcraft"); eq(M.frame:IsShown(),false)
    U.scroll.scripts.OnMouseUp(U.scroll,"RightButton"); eq(M.frame:IsShown(),true)
    M.overlay.scripts.OnMouseDown(); eq(M.frame:IsShown(),false)
end)
test("hiding the window closes the dropdown and its outside-click overlay",function()
    M:Open("root"); U.frame:Hide()
    eq(M.frame:IsShown(),false); eq(M.overlay:IsShown(),false)
    U:Show("guide")
end)
test("window lock blocks drag-resizing while right-click preferences stay accessible",function()
    S:Set("locked",true); eq(U.resizeGrip:IsShown(),false); eq(U.frame.SetResizableArgs[1],false)
    U.frame.StartMovingArgs=nil; U.frame.scripts.OnDragStart(); eq(U.frame.StartMovingArgs,nil)
    U.frame.scripts.OnMouseUp(U.frame,"RightButton"); assert(M:Invoke("display")); assert(M:Invoke("locked"))
    eq(F.settings.locked,false); eq(U.resizeGrip:IsShown(),true)
    U.resizeGrip.scripts.OnMouseDown(U.resizeGrip,"LeftButton"); eq(U.frame.StartSizingArgs[1],"BOTTOMRIGHT")
end)
test("long instructions scroll inside the card and resizing does not complete a step",function()
    local guide={id="ui-scroll-fixture",title="Synthetic layout",source="Synthetic UI test",verification="live-verified",steps={{id="long",type="MANUAL_INSTRUCTION",text=string.rep("Long readable details.\n",90)}}}
    assert(G:RegisterGuide(guide)); assert(G:Select(guide.id,F.character))
    U:Show("guide"); U:ResizeTo(400,300,false)
    assert(U.scrollRange>0); eq(U.scroll.SetScrollChildArgs[1],U.content)
    U.scroll.scripts.OnMouseWheel(U.scroll,-3); assert(U.scrollOffset>0)
    U:ResizeTo(800,560,false); eq(G.state.completed.long,nil); eq(G.state.current,"long")
    U:Scroll(10000); eq(U.scrollOffset,0)
end)
test("context-menu typography and profession choices preserve leveling progress",function()
    local state=G.state
    M:Open("display"); assert(M:Invoke("font-15")); eq(F.settings.fontSize,15); eq(U.body.SetFontArgs[2],15)
    M:Open("professions"); assert(M:Invoke("profession-mining")); eq(F.character.selectedProfession,"mining"); eq(U.tab,"professions")
    eq(G.state,state); eq(state.completed.long,nil)
    M:Open("targets"); assert(M:Invoke("target-225")); eq(F.modules.ProfessionController.state.target,225)
end)
M:Close()
F.modules.ProfessionController.catalog,F.modules.ProfessionController.state,F.modules.ProfessionController.plan=oldController.catalog,oldController.state,oldController.plan
F.character=old.character
S:Set("compact",old.compact); S:Set("fontSize",old.font); S:Set("locked",old.locked); S:Set("theme",old.theme)
G.guide,G.index,G.state=old.guide,old.index,old.state
U:ResizeTo(old.width,old.height,false); U:Show(old.tab)
