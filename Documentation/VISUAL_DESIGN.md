# The field journal

ForeverXP now uses a Silent Hill 2–inspired atmosphere with an original interface.
James Sunderland is the journal companion, visible in a framed 128 × 128 portrait
panel alongside every view, with his name below the image and original header
notes. The notes change with Routes, Supplies, Options, active
detours and completed guides. They are separate from objective and recipe data.

Visual rules: low-saturation gray-green panels, static translucent fog bands,
rust-colored edges, pale paper-like text, simple selected-tab marks and a thin
progress line. The portrait is a newly generated fan-art illustration, not a game
screenshot or extracted asset. No animation loop, flashing effects, copied
dialogue, music or bundled font is used. Existing client font resources are used
through the guarded candidate UI.

`/fxp theme fog` is the default; `/fxp theme contrast` raises text, border and
selection contrast. Both persist through shared settings. Buttons show a distinct
hover state; selected Route/Supplies/Options and Farm/Buy/Hybrid controls remain
marked. Compact mode hides bottom controls without changing saved progression.

Panels use flat color textures and text; James uses a bundled, power-of-two,
uncompressed TGA. Its original source and export instructions are in `art/`.
Lua tests exercise the
style application and state; they are not a screenshot or a live visual review.
Verify font metrics, line wrapping, scaling and visibility in the actual client
before declaring the theme polished for release.
