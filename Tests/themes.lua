local F,test,eq=...
local U,T,S=F.modules.MainWindow,F.modules.Themes,F.modules.Settings
local previousTheme,previousCompact=F.settings.theme,F.settings.compact
test("settings menu offers all themes, applies clicks immediately and saves the selection",function()
    F.settings.compact=false; U:Show("settings")
    eq(#U.themeControls,4)
    for i,choice in ipairs(T.options) do
        local b=U.themeControls[i]
        eq(b:IsShown(),true); eq(b.label.text,choice.name)
        b.scripts.OnClick(); eq(F.settings.theme,choice.id); eq(F.db.settings.theme,choice.id)
        eq(S:Load(F.modules.SavedVariables.Copy(F.db.settings)).theme,choice.id)
        eq(U.background.SetColorTextureArgs[1],T:Get().panel[1])
        eq(b.background.SetColorTextureArgs[1],T:Get().selected[1])
    end
end)
test("Warcraft and Warhammer themes style every tab and retain James Sunderland",function()
    for _,theme in ipairs({"warcraft","warhammer","fog"}) do
        F:Command("theme "..theme)
        for _,tab in ipairs({"guide","professions","settings"}) do
            U:Show(tab)
            eq(U.title.text,T:Get().journal)
            eq(U.body.SetTextColorArgs[1],T:Get().text[1])
            eq(U.portrait,nil); assert(U.companion.text:find("James Sunderland",1,true))
            eq(U.trim[1]:IsShown(),theme~="fog")
            if tab~="settings" then for _,control in ipairs(U.themeControls) do eq(control:IsShown(),false) end end
        end
    end
end)
test("compact settings can still change themes without overlapping full menu buttons",function()
    S:Set("compact",true); S:Set("theme","fog"); U:Show("settings")
    eq(U.frame.SetHeightArgs[1],245); eq(U.themeCycle:IsShown(),true)
    for _,control in ipairs(U.themeControls) do eq(control:IsShown(),false) end
    U.themeCycle.scripts.OnClick(); eq(F.settings.theme,"warcraft")
    assert(U.themeCycle.label.text:find("Warcraft",1,true))
    U:Show("guide"); eq(U.themeCycle:IsShown(),false)
end)
test("theme preferences migrate safely and normal text has readable contrast",function()
    eq(S:Load({theme="fog"}).theme,"fog"); eq(S:Load({theme="contrast"}).theme,"contrast")
    eq(S:Load({theme="unknown"}).theme,"fog")
    local function luminance(c)
        local function linear(v) return v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4 end
        return 0.2126*linear(c[1])+0.7152*linear(c[2])+0.0722*linear(c[3])
    end
    for _,theme in pairs(T.palettes) do
        for _,background in ipairs({theme.panel,theme.button,theme.selected}) do
            local a,b=luminance(theme.text),luminance(background)
            assert((math.max(a,b)+0.05)/(math.min(a,b)+0.05)>=4.5,"Unreadable theme text")
        end
    end
end)
S:Set("theme",previousTheme); S:Set("compact",previousCompact); U:Show("guide")
