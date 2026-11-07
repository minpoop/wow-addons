# The field journal

Version 0.5.1 removes the character portrait, its frame, nameplate and sidebar.
Guide text, progress, settings and profession controls now use the full 540-pixel
content width in the existing 576-pixel window. Compact mode also uses that width.
James Sunderland remains only in the original companion header notes, separate
from quest instructions. Those notes change with the active view and guide state.

Options provides four persisted choices:

1. Silent Hill: low-saturation gray-green panels, static fog bands, oxidized edges,
   pale text and a thin progress line. This remains the default.
2. Warcraft: parchment, brown ink, brass framing and an adventurer’s journal header.
3. Warhammer 40K: gunmetal, crimson, bone text, corner studs and a crusade log header.
4. High contrast: the existing brighter-text variant of the field journal.

Selection applies immediately to all tabs. Compact Options offers one cycling
button. Slash alternatives are `/fxp theme fog`, `warcraft`, `warhammer` or
`contrast`. Existing settings and gameplay progress are retained.

All current visuals use procedural color textures and existing client fonts.
No image asset, franchise music or copied dialogue is included in the addon ZIP.
The old generated portrait source remains in art/ as an unused development
reference. Source-rendered previews use mocked client frames; they are not game
screenshots. Tests exercise theme application, state, full-width layout and
portrait exclusion from packaging. Live font and layout review remains pending.
