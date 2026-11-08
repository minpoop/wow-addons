local F = ForeverXP
local T = F:Register("Themes", {})
T.companion = "James Sunderland"
T.options = {
    {id="fog",name="1 · Silent Hill"},
    {id="warcraft",name="2 · Warcraft"},
    {id="warhammer",name="3 · Warhammer 40K"},
    {id="contrast",name="High contrast"},
}
-- Original companion lines, kept separate from authored quest instructions.
function T:Note(tab)
    if tab == "professions" then return "Count your supplies before moving on." end
    if tab == "settings" then return "Keep the important things in sight." end
    if F.modules.Detours.active then return "Remember the road you came from." end
    if F.modules.GuideEngine.state and F.modules.GuideEngine.state.finished then return "A page ends. The road goes on." end
    return "One step at a time."
end
-- Original procedural styling: no game screenshots, franchise art or audio.
T.palettes = {
    fog = {
        name="Silent Hill", journal="FOREVER XP  /  FIELD JOURNAL",
        panel={0.065,0.082,0.077,0.98}, fog={0.52,0.58,0.53,0.025},
        text={0.82,0.84,0.76,1}, muted={0.61,0.67,0.61,1},
        accent={0.74,0.60,0.45,1}, border={0.39,0.27,0.22,1},
        button={0.12,0.15,0.13,1}, hover={0.21,0.25,0.21,1},
        selected={0.24,0.29,0.24,1}, track={0.15,0.19,0.17,1}, progress={0.54,0.64,0.52,1},
    },
    contrast = {
        name="High contrast", journal="FOREVER XP  /  FIELD JOURNAL",
        panel={0.025,0.035,0.03,1}, fog={0.52,0.58,0.53,0.01},
        text={0.95,0.96,0.90,1}, muted={0.80,0.84,0.78,1},
        accent={0.95,0.80,0.62,1}, border={0.68,0.48,0.37,1},
        button={0.14,0.18,0.15,1}, hover={0.26,0.32,0.26,1},
        selected={0.29,0.35,0.29,1}, track={0.18,0.22,0.19,1}, progress={0.74,0.84,0.69,1},
    },
    warcraft = {
        name="Warcraft", journal="FOREVER XP  /  ADVENTURER'S JOURNAL", ornament=true, mark="AZEROTH CHRONICLE\nADVENTURER'S SEAL",
        panel={0.77,0.67,0.47,1}, fog={0.34,0.22,0.09,0.035},
        text={0.13,0.08,0.035,1}, muted={0.24,0.14,0.065,1},
        accent={0.29,0.10,0.035,1}, border={0.40,0.24,0.075,1},
        button={0.66,0.50,0.29,1}, hover={0.87,0.74,0.48,1},
        selected={0.91,0.77,0.48,1}, track={0.37,0.27,0.14,1}, progress={0.24,0.37,0.15,1},
    },
    warhammer = {
        name="Warhammer 40K", journal="FOREVER XP  /  CRUSADE FIELD LOG", ornament=true, mark="CRUSADE ARCHIVE\nEXPEDITION RECORD",
        panel={0.045,0.055,0.075,1}, fog={0.43,0.07,0.055,0.06},
        text={0.87,0.84,0.73,1}, muted={0.65,0.68,0.70,1},
        accent={0.88,0.68,0.33,1}, border={0.55,0.14,0.105,1},
        button={0.17,0.075,0.085,1}, hover={0.30,0.10,0.105,1},
        selected={0.36,0.12,0.12,1}, track={0.19,0.21,0.24,1}, progress={0.72,0.24,0.17,1},
    },
}
-- Separate reading surface and outer chrome keep every skin legible.
T.palettes.fog.card={0.09,0.112,0.101,1}
T.palettes.fog.headerText={0.87,0.89,0.81,1}
T.palettes.fog.chromeText={0.64,0.71,0.65,1}
T.palettes.fog.titleFont="Fonts\\ARIALN.TTF"
T.palettes.contrast.card={0.05,0.07,0.055,1}
T.palettes.contrast.headerText=T.palettes.contrast.text
T.palettes.warcraft.card={0.79,0.69,0.50,1}
T.palettes.warcraft.panel={0.105,0.073,0.042,1}
T.palettes.warcraft.headerText={0.96,0.80,0.48,1}
T.palettes.warcraft.chromeText={0.80,0.71,0.54,1}
T.palettes.warcraft.border={0.53,0.36,0.14,1}
T.palettes.warhammer.card={0.067,0.075,0.09,1}
T.palettes.warhammer.headerText={0.94,0.79,0.48,1}
T.palettes.warhammer.chromeText={0.69,0.70,0.70,1}
T.palettes.warhammer.titleFont="Fonts\\MORPHEUS.TTF"
-- Worded warnings also use distinct colors; meaning never depends on color alone.
T.palettes.fog.warning={0.96,0.76,0.36,1}; T.palettes.fog.danger={1,0.56,0.49,1}
T.palettes.contrast.warning={1,0.90,0.50,1}; T.palettes.contrast.danger={1,0.68,0.60,1}
T.palettes.warcraft.warning={0.33,0.19,0.025,1}; T.palettes.warcraft.danger={0.45,0.055,0.035,1}
T.palettes.warhammer.warning={1,0.80,0.38,1}; T.palettes.warhammer.danger={1,0.56,0.49,1}
function T:Cycle()
    for i,choice in ipairs(self.options) do
        if choice.id==F.settings.theme then return F.modules.Settings:Set("theme",self.options[i % #self.options+1].id) end
    end
end
function T:Get()
    local name = F.settings and F.settings.theme or "fog"
    return self.palettes[name] or self.palettes.fog
end
function T:Texture(texture, color)
    if texture.SetColorTexture then texture:SetColorTexture(color[1],color[2],color[3],color[4])
    else texture:SetTexture(color[1],color[2],color[3],color[4]) end
end
function T:Text(label, color) label:SetTextColor(color[1],color[2],color[3],color[4]) end
