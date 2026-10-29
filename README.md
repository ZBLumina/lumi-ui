# Lumi UI

A high-quality Luau UI library for executor environments.

> **Status:** experimental pilot (`v0.1`). The first target environment is Potassium.

## Run the placeholder pilot

For the current executor test, run this single line in Potassium:

```luau
loadstring(game:HttpGet("https://raw.githubusercontent.com/ZBLumina/lumi-ui/main/dist/LumiUI.pilot.luau"))()
```

The same loader is stored in [`examples/potassium-loader.luau`](examples/potassium-loader.luau). The standalone artifact lives at [`dist/LumiUI.pilot.luau`](dist/LumiUI.pilot.luau).

This build intentionally contains placeholder controls only. It does not contain game-specific behavior. Re-running it should replace the previous Lumi pilot root instead of stacking duplicate windows.

## Pilot goals

The first iteration intentionally stays small. It exists to validate the architecture, interaction feel, and visual direction before adding advanced systems.

Current pilot surface:

- draggable main window
- sidebar tabs
- central content area
- right-side inspector panel
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

## Design direction

The pilot takes structural inspiration from dense desktop-style tool UIs: sidebar navigation, a focused workspace, compact controls, and an optional inspector/details column. The visual language itself is original to Lumi: dark charcoal surfaces, warm cream/taupe accents, restrained borders, and short functional animations.

## What to test in Potassium

1. The window appears once and is centered.
2. The top bar can drag the complete window.
3. `Home`, `Player`, and `Visuals` switch pages correctly.
4. Toggle animations and state changes work.
5. The slider follows the mouse and remains inside its range.
6. The dropdown opens and selects values.
7. The placeholder button invokes its callback.
8. The inspector updates when controls are used.
9. Re-running the one-line loader replaces the previous UI.
10. The close button destroys the pilot cleanly.

If Potassium reports an error, preserve the exact error text and line number so the failing component can be isolated without redesigning unaffected code.

See [`docs/design/pilot-v0.1.md`](docs/design/pilot-v0.1.md) and the implementation plan under [`docs/superpowers/plans/`](docs/superpowers/plans/).
