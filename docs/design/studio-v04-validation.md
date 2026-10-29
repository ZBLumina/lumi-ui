# Studio v0.4 validation — 2026-10-29

Environment: actual Roblox client, Potassium PID 7740, 1920 x 1080 viewport, gethui available. Tests and source were dispatched with Potassium's execute_script and read back from its console. Native screenshots and mouse actions used the Windows Computer Use integration. No game state was changed by library logic.

## Baseline and design review

Inspected every tracked file at e6c89df: README, v0.1 design and plan, standalone v0.3 pilot, stable loader. Ran the original raw loader successfully and viewed it in Roblox. The old render had overlapping navigation icons/labels, 8–10px copy, redundant row surfaces, unused dark workspace and a generic inspector. README still identified v0.2 while the artifact was v0.3.

The new desktop render was observed repeatedly in Roblox: clearer branding and navigation hierarchy, warm differentiated surfaces, fewer nested boxes, larger text, compact property groups, actual value/type/page/section/range metadata, and stateful controls. The inspector's ruler visualizes scalar values, boolean state and selection ordinal; it does not represent game telemetry.

## Real runtime assertions

Final executed suite: **27/27 passed, zero failures**, console sequence 380 dispatch / 381–410 output. Two warnings intentionally exercise failing callbacks. No other errors occurred in that final suite.

Coverage includes actual mounted Instances; construction API; equal/reversed/clamped/nonfinite slider ranges; empty, invalid and singleton dropdowns; state-before-callback; silent setters; throwing and yielding callbacks; popup teardown on tab changes; double Destroy; external root destruction; independent windows; false-value inspector state; gethui-local centering; explicit selection surviving deferred initialization; non-divisible slider endpoints; complete-library reinjection; compact bounds; precise input focus/blur; cancellation of suspended callbacks; and obsolete library handles.

Regressions observed failing before their fixes:

- Original v0.3: Min=Max=10, Default=100 returned 11 instead of 10.
- First modular render: false toggle inspector displayed Ready; gethui's -58 Y inset was counted twice when centering; deferred selection replaced explicit focus; Step=0.3 could not reach Max=1. Suite was 17/21, then 21/21 after fixes with unchanged assertions.
- Independent review findings: focus/blur changed Step=0.001 value 0.123 to approximately 0.12; suspended callback resumed after Destroy; obsolete library handle created an orphan window; compact 640 x 360 text shrank below 11px. Suite was 23/27, then 27/27 after fixes with unchanged assertions for those four cases.

The earlier compact-divider assertion used a hardcoded width. It was replaced with a visible-bounds assertion when compact layout intentionally changed from scaling to reflow; the test now checks overflow rather than a particular design dimension.

## Real mouse interaction

- Dropdown: selected Smooth; stored selection, selector and inspector changed together, callback logged.
- Toggle: switched off; Disabled appeared, indicator/ruler changed and callback logged false.
- Slider: dragged 65 to 92; input release left no active pointer, inspector showed 92%.
- Button: callback logged, Completed feedback and inspector execution count appeared.
- Window: title drag moved center from (960,540) to (1060,580); shadow moved with it and pointer released.
- Navigation: switched to Visuals through its real sidebar button.
- Long dropdown: opened upward near lower boundary; native wheel moved its own canvas to (0,186) while page stayed at (0,0); selected final option Oat.
- Empty dropdown: observed No options available and No selection in the inspector.
- Outside dismissal: a click on the dismissal layer closed the menu without changing selection.

The Windows key injection tool did not deliver Keyboard InputBegan events in this client. A separate VirtualInputManager Escape event did reach Roblox (processed=true) and closed Lumi's menu/dismissal layer. It also invokes Roblox's normal pause menu, which was restored with a second engine Escape. Physical keyboard navigation and physical touch input are not verified.

## Responsive checks and visual limit

An 800 x 600 simulated GUI viewport was rendered and visually inspected. The first scaled version fit but made text smaller. Following review, compact mode was changed to resize/reflow and scroll instead. Final real-runtime measurements at a simulated 640 x 360 container: window 608 x 328, scale 1, workspace 468 x 252, inspector hidden, body TextSize 13. Tests assert usable body text and bounded geometry.

The user stopped Computer Use with physical Escape before the final compact reflow screenshot. Therefore the final compact layout is runtime-asserted, but its final screenshot/physical interaction review remains pending. The final reflow also adapts wide short viewports by hiding the inspector, using a shorter shell and allowing page scrolling. No claim is made that every device or physical touch gesture was tested.

## Independent review disposition

One fresh reviewer inspected the implementation read-only. No Critical findings. All four Important findings were reproduced and fixed with RED-to-GREEN regressions. The review's Minor finding remains documented: programmatic dropdown Set while open does not refresh the menu's existing checkmark until reopening. The selector, stored value and inspector do update.

Reviewer exclusions were handled explicitly: hardware touch/keyboard and final responsive appearance remain verification limits above; gameplay remains out of scope; documentation is supplied here. No hidden game-specific behavior was added.

## Build and reproducibility

Node-built standalone artifacts contain all local module factories; there are no runtime network module imports. `node --check scripts/build.mjs`, `npm run build`, `npm run check`, and repeated build hashes were checked. Tests use real Roblox services rather than mocks. Build checks detect stale output without rewriting it and reject missing/circular module imports. The test runner is generated to `tests/runtime.bundle.luau` and excluded from Git.

## Decisions recorded

- Retained the public construction API; added Get/Set/Focus and action/popover methods. Button is an action, not a value setter.
- Used a fresh clone and feature branch for isolation; no changes to another existing checkout.
- Kept the stable main loader intact; the review branch requires its own raw URL until merged.
- Chose a property-editor layout over a dashboard grid; compact layout now reflows after review.
- Destruction is terminal for a library handle. Reload to create a fresh library. Lumi cancels its own suspended callback threads; independently spawned user work is outside that lifetime.
- Left the one Minor menu-marker issue visible in README and this record rather than hiding it behind a green suite.
