# Lumi UI

A high-quality Luau UI library for executor environments.

> **Status:** experimental pilot (`v0.1`). The first target environment is Potassium.

## Pilot goals

The first iteration intentionally stays small. It exists to validate the architecture, interaction feel, and visual direction before adding advanced systems.

Planned pilot surface:

- draggable main window
- sidebar tabs
- central content area
- optional right-side details panel
- sections
- button
- toggle
- slider
- dropdown
- lightweight transitions
- clean reinjection / destroy behavior
- executor-aware GUI mounting

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

The pilot takes structural inspiration from dense desktop-style tool UIs: sidebar navigation, a focused workspace, compact controls, and an optional inspector/details column. The visual language itself will be original to Lumi: dark charcoal surfaces, warm cream/taupe accents, restrained borders, and short functional animations.

## Development

The initial implementation will be standalone Luau so it can be pasted directly into Potassium during early testing. Packaging and remote loading come later, after the pilot is stable.

See [`docs/design/pilot-v0.1.md`](docs/design/pilot-v0.1.md) and the implementation plan under [`docs/superpowers/plans/`](docs/superpowers/plans/).
