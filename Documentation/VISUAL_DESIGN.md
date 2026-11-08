# The field journal — 0.7

The main window centers a current-task card with a phase label, title, context,
scrollable instruction body and a thin progress line. A separate navigation strip
keeps the destination visible. No action buttons or portrait occupy the reading
area. Right-click opens a cursor-anchored, screen-clamped dropdown; submenus expose
all previous window actions. Click outside, choose an action or press Escape to
close it. `/fxp menu` is the keyboard fallback.

Default size is 620×420 UI units. The lower-right grip resizes between 380×260 and
980×820 using native frame sizing; both dimensions persist per character. Text
reflows and scrolls within the card. Small/compact layouts reduce spacing and hide
the companion line; they retain the chosen dimensions. Lock prevents moving and
resizing. Window & text provides font sizes, presets and opacity. Shared account
preferences remain distinct from per-character position, size and progress.

Four themes apply immediately without changing gameplay progress:

1. Silent Hill: gray-green card, muted fog bands, oxidized frame and pale text.
2. Warcraft: dark leather-colored surround, parchment card, brown ink and brass.
3. Warhammer 40K: gunmetal, crimson, bone text and gold headings.
4. High contrast: brighter field-journal text and stronger separation.

James Sunderland remains in original companion header notes when space permits.
The portrait and nameplate remain removed. Native client fonts and procedural
textures supply the styling. The only packaged image is a small original arrow
(`art/NavigationArrow.svg` is its authoring source); no extracted franchise art,
copied dialogue or music is included. Historical portrait art is unused.

Source-rendered previews use the actual UI modules and mocked frame geometry.
They are not game screenshots, and font metrics/wrapping may differ. Offline tests
cover native resize callbacks, persistence, scrolling, locking, menu dismissal,
button removal and theme/state separation. Native rendering and interaction still
need the live checklist.
