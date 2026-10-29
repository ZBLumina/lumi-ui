# v0.4.4 — a more considered workspace

The user delegates another creative visual pass, including live PC inspection. This extends the existing authorization to implement and verify the pilot on its preview branch. The current Roblox render is the baseline, not a web mockup.

## Direction

Keep the warm charcoal/cream palette, readable v0.4.2 type and short v0.4.3 motion. Improve orientation and selection rather than adding decoration. Preserve the 1100 x 660 desktop shell, compact layout, construction API, callbacks, pointer behavior and cleanup.

Considered three approaches: more ornamental surfaces (adds noise without useful information); a new layout (unnecessary disruption to an already liked interface); contextual refinement (chosen by the implementer under delegated creative discretion). The last improves hierarchy and communicates actual state while preserving the current interaction model.

Use small native geometric navigation icons, real control counts, a clearer page heading and an inset wash behind the selected property. Give the inspector a different lower graphic for numeric ranges, boolean states, discrete options and actions. A dropdown must not look like a continuous numerical measurement. Keep minimum 11px shared labels and 14px property names. No gradients, glow, external assets, bounce or perpetual motion.

## Implementation plan

1. Add a small `components/Inspector.luau` presentation module; retain Window's existing detail fields as aliases. Preserve immediate text updates. Numeric rulers show bounds and position, booleans show Off/On, dropdowns show their actual ordinal/count (including empty collections), actions show their session status. `SetDetails` must clear control-specific graphics.
2. Refine Tab navigation with optional built-in `Icon` choices (`Grid`, `Sliders`, `Layers`, default Grid), actual control counts, a quieter active outline and a stronger page title. Refresh counts when sections/controls are constructed. Add an inset selection wash through the existing Focus path, with no extra input listener per row.
3. Rebuild and execute the existing 38 real Roblox integration cases unchanged. These reversible presentation edits do not need tests that merely restate colors/coordinates. Verify the new contextual semantics directly in the real runtime, including empty/fixed values, rapid selection, long names and compact dimensions. Add a regression only if a behavioral defect is found.
4. Inspect Overview, Player, Visuals, dropdowns and selected rows in Roblox at desktop and compact sizes. Keep the changes that improve the actual render. Review the final diff, document evidence, regenerate/copy the standalone pilot, commit and push to the existing draft PR.

## Review focus

- Switching control kinds cannot leave a stale ruler/state graphic visible.
- Fixed numeric ranges and empty dropdowns must remain meaningful without arithmetic errors.
- Focus wash and icon/count changes must survive interrupted entrance/page motion.
- Compact rows must retain their full hit areas and readable labels; counts must not overlap tab names.
- No detached inspector connection, tween or popup may survive reinjection or destruction.

## Validation

Completed in Roblox through Potassium, client PID 30488, 1920 x 1080. The final generated bundle passes the original **38/38** real Roblox integration cases unchanged (console summary sequence 1242). The two intentional callback-error warnings are expected. `npm run build`, `npm run check` and `git diff --check` pass.

Live screenshots were inspected for the numeric, boolean and discrete-option inspector, the Overview layout and open popover. Engine VirtualInputManager events exercised actual GUI signals: toggle changes to Disabled with the OFF tile selected; selecting Smooth updates `OPTION 02 / 03` and closes the popup; the action reports `1 completed`; the Player tab settles and a fixed slider stays at 10 with `FIXED`; the empty dropdown retains nil and shows `NO OPTIONS` plus its empty popover. Programmatic focus on Ivory shows `OPTION 11 / 12`. A temporary 15-option fixture shows the exact ordinal without pretending that twelve marks represent fifteen entries; moving to an empty page clears all old control graphics. Fixtures were destroyed.

Rapid page changes leave one selected property wash and restore its baseline opacity. The exploratory checker initially compared an engine float32 opacity with exact decimal 0.4; measuring 0.400000005960 identified a checker precision issue, resolved with an epsilon comparison. Its first compact check also incorrectly expected the page summary to hide at a width where it fits; the actual requirement is to hide narrow **navigation** counts and preserve readable tab/title text. Both were corrected without changing the corresponding product behavior.

The available viewport was simulated at 640 x 360 (same root-frame method as the existing integration tests). The shell is 608 x 328 at scale 1; inspector and sidebar counts hide, the page heading and tab names fit, and property names stay 14px. Live inspection exposed wasted vertical branding space, so short sidebars now reduce that spacing: all three 42px demo navigation targets fit, with no clipping. More tabs still scroll. The narrow branding subtitle becomes `UI LIBRARY` to avoid truncation. Desktop dimensions and the inspector were restored afterward.

Independent read-only review found no Critical/Important regressions. Its minor count-cap observation was resolved by keeping the actual count in the label and hiding the sidebar count above 999, where its reserved width is insufficient; the page summary retains the exact count. This is a reversible presentation adjustment, not a changed control contract. The final suite ran after these final layout/count changes.

Native Windows click injection did not consistently update Roblox's engine cursor in this session. Native snapshots were used for visual inspection, and the engine input API was used for deterministic GUI interaction, accounting for the observed 58px gethui/inset offset. This is not physical touch/gamepad verification. No gameplay logic, external assets or new dependencies were added. Physical touch/gamepad checks and the previously documented programmatic-open-dropdown marker limitation remain outside this presentation pass.
