# Lumi UI Pilot v0.1 — Design

## Intent

Build a small but real reusable Luau UI library that can be executed in Potassium and used to judge the core experience before expanding into a larger framework.

## Goals

- Provide a reusable API rather than a one-off ScreenGui.
- Run as a standalone script in Potassium for early testing.
- Mount safely in an executor environment and clean up previous instances on reinjection.
- Deliver a polished Lumi visual direction without overbuilding the first version.
- Include enough controls to test layout, input, callbacks, and interaction quality.

## Non-goals for v0.1

- Multiple themes.
- Config serialization.
- Color picker.
- Advanced keybind manager.
- Notification center.
- Command palette.
- Plugin system.
- Remote dependency loading.

## Visual direction

The reference UI is used only for composition ideas: sidebar navigation, a broad workspace, compact settings rows, cards, and an optional right-side details panel. Lumi will not clone its branding or internal game content.

The initial Lumi palette uses dark charcoal surfaces with warm cream/taupe accents, subtle outlines, rounded geometry, clear type hierarchy, and short restrained transitions.

## Public API target

```luau
Lumi:CreateWindow(options)
Window:AddTab(name)
Tab:AddSection(name)
Section:AddButton(options)
Section:AddToggle(options)
Section:AddSlider(options)
Section:AddDropdown(options)
Window:Destroy()
```

Every interactive control accepts a callback. Controls retain their current value internally and expose predictable behavior under repeated interaction.

## Runtime assumptions

- Roblox Instances are used for the UI rather than a Drawing-only implementation.
- The mount layer detects the best available GUI parent for the executor environment.
- Re-running the pilot must not leave duplicate Lumi windows.
- The first distribution format is one standalone Luau test script.

## Approaches considered

### 1. One large standalone script
Fastest to prototype, but becomes difficult to maintain once the pilot grows.

### 2. Modular source + generated standalone build — selected
Develop focused modules by responsibility, then expose a single bundled pilot for Potassium testing. This keeps the codebase maintainable without making early testing inconvenient.

### 3. Drawing-only UI
Executor-friendly in theory, but unnecessarily recreates layout, clipping, scrolling, and input behavior that Roblox GUI objects already provide.

## Success criteria

The pilot is successful when it can be repeatedly executed in Potassium, shows one clean window, supports drag/navigation/basic controls, invokes callbacks correctly, destroys cleanly, and feels responsive enough to justify expanding the library.
