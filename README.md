# Lumi UI

A high-quality Luau UI library for executor environments.

> **Status:** experimental visual pilot (`v0.2`). The first target environment is Potassium.

## Run the current pilot

Run this single line in Potassium:

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/main/dist/LumiUI.pilot.luau"))()
```

The same loader is stored in [`examples/potassium-loader.luau`](examples/potassium-loader.luau). The standalone artifact lives at [`dist/LumiUI.pilot.luau`](dist/LumiUI.pilot.luau).

This build contains placeholder controls only; it does not contain game-specific behavior. Re-running it replaces the previous Lumi pilot root instead of stacking duplicate windows.

## v0.2 visual direction

The second pilot keeps the working Luau API but rebuilds the presentation around a denser desktop-style layout:

- narrower navigation rail with active states
- dedicated page headers and clearer hierarchy
- compact contextual inspector
- layered charcoal surfaces instead of one flat grey field
- cream/taupe Lumi accents used for state and selection
- redesigned button, toggle, slider, and dropdown components
- floating dropdown menus
- restrained hover and transition feedback
- Potassium status/footer treatment instead of the old debug badge

## Current pilot surface

- draggable main window
- sidebar tabs
- central content area
- right-side contextual inspector
- sections
- button
- toggle
- slider
- dropdown
- lightweight transitions
- clean reinjection / destroy behavior
- executor-aware GUI mounting (`gethui()` with `CoreGui` fallback)

## Intended API

```luau
local Lumi = -- library

local Window = Lumi:CreateWindow({
    Title = "Lumi",
})

local Main = Window:AddTab("Home")
local General = Main:AddSection("General")

General:AddToggle({
    Name = "Enabled",
    Default = false,
    Callback = function(value)
        print("Toggle:", value)
    end,
})
```

## What to test in Potassium

1. The window appears once and is centered.
2. The top bar drags the complete window and its shadow together.
3. `Home`, `Player`, and `Visuals` switch pages correctly.
4. Toggle animation and state changes work.
5. The slider follows the mouse and remains inside its range.
6. The dropdown opens as a floating menu and selects values.
7. The placeholder button invokes its callback.
8. The context panel updates when controls are used.
9. Re-running the one-line loader replaces the previous UI.
10. The close button destroys the pilot cleanly.

If Potassium reports an error, preserve the exact error text and line number so the failing component can be isolated without redesigning unaffected code.

See [`docs/design/pilot-v0.1.md`](docs/design/pilot-v0.1.md) and the implementation plan under [`docs/superpowers/plans/`](docs/superpowers/plans/).
