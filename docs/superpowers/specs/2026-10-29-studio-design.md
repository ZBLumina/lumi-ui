# Lumi Studio pilot v0.4

The supplied brief authorizes autonomous design and implementation. This is a Roblox GUI library, not the Lumi website. No game logic, downloaded assets, or remote module dependencies.

## Baseline
Inspected all six existing files at e6c89df and ran v0.3 in Potassium PID 7740. Live screenshot: 950 x 540 shell, 8–10 px body text, nav glyphs overlap labels, redundant outlines around every row, mostly empty black workspace and generic inspector. Global input connections survive root destruction. Equal slider bounds are silently changed.

## Direction and choices
Use a warm desktop property editor: 1100 x 660 desktop canvas, 184 px sidebar, 220 px contextual rail, 48 px chrome, 28 px status bar. Compact layouts resize/reflow and scroll rather than shrinking all text: collapse the inspector below 850px wide or 692px high, use a 140px sidebar below 700px wide, and stack actions when a property row is narrower than 560px. Preserve a draggable title strip inside screen bounds. Body text 13, secondary 11, title 26. Sidebar has a geometric Lumi mark, brand, navigation group, numbered pages, selected cream wash, bottom build identity. Avoid nested row cards: shared section surfaces with dividers. Solid cream action buttons; squared precision toggles with explicit ON/OFF; numerical sliders with endpoints and ticks; an unclipped scrolling dropdown popover above a root-level dismissal layer, with Escape, viewport clamping and selection check geometry.

Inspector earns its space with a geometric value ruler, large live value, control description and metadata (page, section, type, range/options). It selects on focus or interaction and stays synchronized with programmatic setters. Preserve readable central content when collapsed.

Alternatives: cosmetic repair preserves the baseline's weak hierarchy; a two-column dashboard fragments the property workflow at this width. Chosen by the implementer under the user's creative authorization: compact full-width property groups plus a dedicated context rail.

## Architecture and API
Modules use string require IDs resolved by the Node bundler. Runtime owns connections, active tweens, callback threads and cleanup; the library owns the persistent getgenv registry. One current library per executor; reinjection destroys the previous library before mounting. Destroy is idempotent and terminal; external root destruction also releases resources. Suspended callbacks owned by Lumi are canceled, while a callback destroying its own window may finish its current invocation. gethui with protected fallback to CoreGui then PlayerGui. No legacy executor APIs.

Preserve CreateWindow / AddTab / AddSection / AddButton / AddToggle / AddSlider / AddDropdown and Get. Add Set(value, silent), Focus, button Press, dropdown Open/Close, Window SelectTab, options Description / Action / Step / Suffix. Invalid dropdown defaults fall back to the first item; empty lists return nil. Equal bounds are fixed values; reversed bounds normalize, defaults clamp, nonfinite numbers use a safe fallback. State updates precede protected asynchronous callbacks. Pointer ownership ends on release, focus loss, tab changes and destroy. Support mouse, touch and focused arrow keys for sliders.

## Validation
Run actual Roblox assertions against the bundled library; do not emulate Roblox Instances. Exercise range normalization, dropdown empty/single/invalid default, callback errors, API updates, global connection cleanup, reinjection and repeated destroy. Capture and operate the real Roblox window: tabs, toggle, slider dragging, dropdown selection/outside/Escape, button feedback, window drag. Record visual refinements and exact limits honestly. Build twice and compare output for reproducibility. Push clear commits only after verification; keep main unchanged and supply a reviewable branch/PR.
