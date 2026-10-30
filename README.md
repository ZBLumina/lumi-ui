# Lumi UI

A modular Luau interface library for Potassium. **v0.4.6 is a visual pilot**: warm charcoal surfaces, compact property groups, restrained motion, and a contextual inspector. Demo actions affect the interface only.

Property rows now measure and wrap their text, keep clear gaps between captions and fields, and stack fields when space is insufficient. Controls share a 32px visual height; sliders have separate drag/bounds lanes and a padded value field. Narrow popovers contain their captions and empty states. See the [layout design and validation](docs/design/studio-v046-layout.md).

The panel shadow now uses a smooth ambient falloff and a tighter contact shadow, with antialiased native geometry that follows resizing and animation. The bottom-right silhouette also matches the rounded shell. See the [shadow notes and validation](docs/design/studio-v045-shadow.md).

The latest design pass adds native geometric navigation icons, actual control counts, a clearer page heading and an inset selection wash. The inspector now distinguishes numeric ranges, binary states, discrete options (including empty collections), and actions. Its graphics explain the selected control rather than showing the same meter everywhere. See the [context design and validation](docs/design/studio-v044-context.md).

Motion uses short Quart Out transitions: a 220ms window entrance, 160ms user dismissal, 140ms page reveal, brief popovers, tactile button feedback and smooth slider presentation. Values and tab state change immediately; dragging follows the pointer directly. Use `Window:Close()` for animated dismissal; `Window:Destroy()` remains immediate for cleanup/reinjection. Set `Animations = false` in `CreateWindow` to disable interpolation and button pulses. See the [motion design and validation](docs/design/studio-v043-motion.md).

The readability pass raises text contrast, sets an 11px minimum for shared text labels, uses 14px medium-weight property names and 12px descriptions, and makes navigation, dropdown and inspector text easier to read. Layout and control behavior remain unchanged.

The finesse pass refines type weights, outlines and spacing; gives the inspector its own inset surface and fine value ruler; and preserves comfortable hit areas behind more delicate visible controls. Buttons accept `Variant = "Secondary"` for a quiet outlined treatment. The default remains the cream primary action. See the [finesse notes](docs/design/studio-v04-finesse.md).

## Run the pilot

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/main/dist/LumiUI.pilot.luau"))()
```

The loader follows `main`. To preview an unmerged branch, replace `main` with that branch or a commit SHA. `examples/potassium-loader.luau` retains the stable loader.

## Use the library

`dist/LumiUI.luau` returns the library without creating demo content. `dist/LumiUI.pilot.luau` includes the three-page playground.

```luau
local Lumi = loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/main/dist/LumiUI.luau"))()
local Window = Lumi:CreateWindow({Title = "Lumi"})
local Home = Window:AddTab("Home", {Description = "Your local workspace."})
local General = Home:AddSection("General")

local enabled = General:AddToggle({Name = "Enabled", Default = false,
    Callback = function(value) print(value) end})
local intensity = General:AddSlider({Name = "Intensity", Min = 0, Max = 100,
    Default = 65, Step = 1, Suffix = "%", Callback = function(value) print(value) end})
General:AddDropdown({Name = "Mode", Values = {"Default", "Smooth", "Precise"},
    Default = "Default", Callback = function(value) print(value) end})
General:AddButton({Name = "Execute", Action = "Run preview",
    Callback = function() print("Executed") end})

enabled:Set(true)           -- state first, callback asynchronously
intensity:Set(40, true)     -- silent update
intensity:Focus()           -- select in inspector
print(intensity:Get())
-- Window:Close()           -- short animated dismissal, safe to repeat
-- Window:Destroy()         -- immediate cleanup, safe to repeat
-- Lumi:Destroy()           -- destroys all owned windows
```

All controls accept `Name`, `Description`, and `Callback`. Value controls expose `Get()`, `Set(value, silent?)`, and `Focus()`. Buttons expose `Press()` and a display status through `Get()`. Dropdowns also expose `Open()` / `Close()`.

Tabs optionally accept `Icon = "Grid"`, `"Sliders"`, or `"Layers"`. Missing or unknown icon names use Grid. Icons use native GUI geometry; no external images or special font glyphs are required. Navigation counts hide on narrow sidebars to preserve tab labels.

- Slider bounds normalize if reversed. Equal bounds stay fixed. Defaults and setters clamp; invalid/nonfinite numbers use safe finite fallbacks. `Step` defaults to 1. Both endpoints remain reachable. Click the numeric value to type a value; focused sliders support left/right arrows.
- Dropdown defaults fall back to the first value when invalid; empty lists keep `nil`. Invalid setters leave state unchanged. Long lists scroll; menus close on outside click, Escape, tab change, content scroll, window move, or focus loss.
- State changes precede protected asynchronous callbacks. Errors are logged without breaking the control. Destruction cancels suspended callbacks started by Lumi. Work independently spawned by user callbacks remains the caller's responsibility. A callback that destroys its own window may finish its current invocation safely.
- Each load replaces the previous Lumi library through an executor environment registry. Windows within the same library remain independent. Mounting tries `gethui()`, `CoreGui`, then an existing `PlayerGui`. Destruction disconnects tracked input/service connections and cancels active UI tweens.
- The desktop canvas is 1100 x 688. Viewports that cannot fit the desktop hide the inspector and adapt the window dimensions before scaling. Property names remain 14px and descriptions 12px; long text grows its row and fields stack when needed. Compact content scrolls. Extremely small viewports can still scale down. Mouse and touch paths are implemented; the validation record states which paths were exercised.

Known pilot limitation: changing a dropdown programmatically while its menu is open updates the stored value and selector, but the menu's selection marker refreshes on reopening. Close the menu before programmatic updates when the visual marker matters.

## Develop and build

Requires Node.js 18+; no npm dependencies.

```sh
npm run build
npm run check
```

Edit `src/`, then build. Do not edit generated `dist/` files. Modules use literal source-root-relative imports such as `require("controls/Slider")`; the bundler resolves them locally and rejects missing/circular imports. No module is downloaded at runtime.

```text
src/
  init.luau         API and reinjection registry
  Runtime.luau      mounting, connections, tweens, cleanup
  Theme.luau        warm Lumi tokens
  UI.luau           native GUI primitives
  Window.luau       shell, inspector, input, scaling
  Tab.luau          navigation and scrolling pages
  Section.luau      property groups and shared rows
  PropertyLayout.luau measured caption/field placement
  components/      contextual inspector presentation
  controls/         Button, Toggle, Slider, Dropdown
examples/potassium-pilot.luau   demo content
scripts/build.mjs              standalone bundler
tests/runtime.spec.luau        real Roblox assertions
```

The build also generates `tests/runtime.bundle.luau` (Git-ignored). Execute the whole file through Potassium in a Roblox client. It uses real Instances/service connections, creates temporary windows, prints a `[LUMI TEST] summary`, and cleans up. Two warnings from intentionally throwing callbacks are expected; failures end with an error.

Visual quality is assessed in Roblox separately from the assertion suite. See the [design](docs/superpowers/specs/2026-10-29-studio-design.md), [plan](docs/superpowers/plans/2026-10-29-studio-v04.md), and [validation](docs/design/studio-v04-validation.md).
