local F = ForeverXP
local T = F:Register("Themes", {})
T.companion = "James Sunderland"
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
        panel={0.065,0.082,0.077,0.98}, fog={0.52,0.58,0.53,0.025},
        text={0.82,0.84,0.76,1}, muted={0.61,0.67,0.61,1},
        accent={0.74,0.60,0.45,1}, border={0.39,0.27,0.22,1},
        button={0.12,0.15,0.13,1}, hover={0.21,0.25,0.21,1},
        selected={0.24,0.29,0.24,1}, track={0.15,0.19,0.17,1}, progress={0.54,0.64,0.52,1},
    },
    contrast = {
        panel={0.025,0.035,0.03,1}, fog={0.52,0.58,0.53,0.01},
        text={0.95,0.96,0.90,1}, muted={0.80,0.84,0.78,1},
        accent={0.95,0.80,0.62,1}, border={0.68,0.48,0.37,1},
        button={0.14,0.18,0.15,1}, hover={0.26,0.32,0.26,1},
        selected={0.29,0.35,0.29,1}, track={0.18,0.22,0.19,1}, progress={0.74,0.84,0.69,1},
    },
}
function T:Get()
    local name = F.settings and F.settings.theme or "fog"
    return self.palettes[name] or self.palettes.fog
end
function T:Texture(texture, color)
    if texture.SetColorTexture then texture:SetColorTexture(color[1],color[2],color[3],color[4])
    else texture:SetTexture(color[1],color[2],color[3],color[4]) end
end
function T:Text(label, color) label:SetTextColor(color[1],color[2],color[3],color[4]) end
