local F,test,eq=...
local U,T,S=F.modules.MainWindow,F.modules.Themes,F.modules.Settings
local previousTheme,previousCompact=F.settings.theme,F.settings.compact
test("right-click appearance menu applies every theme immediately and saves the choice",function()
    local menu=F.modules.ContextMenu
    for _,choice in ipairs(T.options) do
        U:Show("settings"); menu:Open("themes")
        assert(menu:Invoke("theme-"..choice.id))
        eq(F.settings.theme,choice.id); eq(F.db.settings.theme,choice.id)
        eq(S:Load(F.modules.SavedVariables.Copy(F.db.settings)).theme,choice.id)
        eq(U.background.SetColorTextureArgs[1],T:Get().panel[1])
        eq(U.cardBackground.SetColorTextureArgs[1],T:Get().card[1])
    end
end)
test("all themes style every view while the main window has no action buttons",function()
    for _,theme in ipairs({"warcraft","warhammer","fog"}) do
        F:Command("theme "..theme)
        for _,tab in ipairs({"guide","professions","settings"}) do
            U:Show(tab)
            eq(U.title.text,"FOREVER XP"); eq(U.body.SetTextColorArgs[1],T:Get().text[1])
            eq(U.portrait,nil); eq(U.buttons,nil); assert(U.companion.text:find("James Sunderland",1,true))
        end
    end
end)
test("compact spacing retains the saved size and theme choices remain in the context menu",function()
    local height=U.height
    S:Set("compact",true); S:Set("theme","fog"); U:Show("settings")
    eq(U.height,height); eq(U.themeControls,nil)
    local menu=F.modules.ContextMenu; menu:Open("themes"); assert(menu:Invoke("theme-warcraft"))
    eq(F.settings.theme,"warcraft")
    eq(U.companion:IsShown(),false)
end)
test("theme preferences migrate safely and normal text has readable contrast",function()
    eq(S:Load({theme="fog"}).theme,"fog"); eq(S:Load({theme="contrast"}).theme,"contrast")
    eq(S:Load({theme="unknown"}).theme,"fog")
    local function luminance(c)
        local function linear(v) return v<=0.04045 and v/12.92 or ((v+0.055)/1.055)^2.4 end
        return 0.2126*linear(c[1])+0.7152*linear(c[2])+0.0722*linear(c[3])
    end
    for _,theme in pairs(T.palettes) do
        for _,background in ipairs({theme.card,theme.button,theme.selected}) do
            local a,b=luminance(theme.text),luminance(background)
            assert((math.max(a,b)+0.05)/(math.min(a,b)+0.05)>=4.5,"Unreadable theme text")
        end
    end
end)
S:Set("theme",previousTheme); S:Set("compact",previousCompact); U:Show("guide")
