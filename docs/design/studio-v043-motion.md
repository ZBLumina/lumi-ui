# v0.4.3 — restrained motion

The user asks for subtle, creative animation across opening, closing, navigation and controls, without a playful or unusual character. Existing creative/implementation authorization applies.

## Direction

Use Quart Out easing with no bounce, spring, spin, particle or perpetual animation. Window entrance: 220ms opacity and a 1% scale settle, fixed center. User close: 160ms fade/1% contraction. Pages: 140ms soft reveal and 4px vertical settle. Popovers: 120ms reveal/4px displacement, 80ms dismissal. Buttons: 70ms press to 97.5%, 120ms return, hover to 101%. Slider values commit immediately; visual fill/thumb settle in 100ms for setters/keyboard, follow pointer directly while dragging, and thumb gains a small active emphasis. Inspector ruler colors and the selected-row marker settle briefly.

Preserve the readable v0.4.2 typography and the existing construction API. `Window:Close()` is an animated user dismissal; `Destroy()` remains synchronous/idempotent for teardown and reinjection. `CreateWindow({Animations=false})` disables motion without an added settings UI. Tab selection and values change immediately. New navigation/input interrupts entrance or previous transitions; no queued old transition may win over current state.

## Implementation plan

1. Add real Roblox RED tests for independent tween channels, owned delayed work, animated Close, rapid tab switches and reinjection during close. Keep all existing expectations intact.
2. Extend Runtime with named tween channels and owned delays; cancel both at destruction. Add a small Motion controller that captures/restores original opacity, owns one progress value/connection per animated group, and cancels obsolete completion work.
3. Apply entrance/dismissal to the shell and popovers, page reveal to navigation, and tactile feedback to controls. Pointer dragging always cancels an unfinished settle. Dismissed popup layers stop accepting input immediately.
4. Build and run the complete real-client suite, exercise actual Potassium interactions, sample intermediate/final states, and verify compact layout plus repeated clicks/navigation. Review race/lifecycle risks independently, fix material findings, then update docs/builds and the existing PR.

## Verification risks

Closing while dragging; rapid switch/open/close; competing size/position/color tweens; cancelled fade restoring a stale opacity; root destruction or reload during a delay; preserving `Destroy()` and callback semantics; long/empty menus and bounds while animating. Physical mobile testing is not implied.

## Validation and fixes

Actual Roblox client through Potassium PID 7740. The original 27 assertions remain unchanged. The expanded suite passes **38/38**, including independent tween channels, owned delays, intermediate close opacity, rapid page switching, reload during close, opt-out, intermediate slider movement, popup replacement and immediate release of GUI selection during dismissal. The expected throwing-callback warnings are retained.

Before implementation, five of the six first new tests failed against v0.4.2. The first candidate exposed a nested-fade race: a deferred window entrance captured a page already transitioning, leaving its text at 0.35 transparency. User navigation now cancels a pending entrance as well as an active one. The channel test's sample Frame was moved from Main to the ScreenGui so window entrance does not contaminate its independent assertion; its expected values stayed unchanged.

Live inspection also found the initial active navigation wash could be captured at an intermediate opacity. Initial selection is now applied immediately before entrance, and hover/navigation interrupts entrance before changing opacity. A regression checks both immediate and resting selection.

One independent read-only review identified two Important issues. Both were reproduced as failing regressions and fixed: retiring options now lose GUI selection/eligibility and gate activation by current popup ownership; disabled motion now skips the delayed button-scale pulse. No second review was used as a substitute for those regressions.

Observed engine samples: opening reached opacity 0.161 and scale 0.998 after approximately 40ms, then opacity 0 / scale 1. Page change reached Y=2px with text transparency 0.160, then settled at Y=0 / transparency 0. These are actual frame properties from the Roblox render, not a Luau mock.

Desktop appearance was inspected with native screenshots. Direct engine input through VirtualInputManager was used for deterministic real GUI activation after the Windows click helper delivered one click using a stale engine pointer location. Page selection and action feedback were checked through the actual GUI signals; popup selection, drag release and animated close were sampled separately. No gameplay actions or game logic were added. Physical touch/gamepad testing remains outside this run.

Real GUI interaction evidence: menu opacity was 0.117 during entrance; selecting Smooth relinquished logical menu ownership immediately, retained its visual exit briefly, then removed the old root. Slider dragging ended at value 75 / fill 0.75 with no owned pointer. Window close reached opacity 0.581 while still mounted, then its root was removed and runtime destroyed. Compact 640 x 360 rendering retained scale 1 and 14px property labels; its long menu remained bounded during the short entrance, and the page settled to Y=0 with full text opacity. Native screenshots were checked and the normal desktop layout restored.
