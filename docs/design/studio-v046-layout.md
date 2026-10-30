# v0.4.6 — measured property layout

The user flags crowded controls and asks to verify order, improve appearance and prevent collisions. Real-client measurements of v0.4.5 confirm that slider endpoint labels end only 3px before the next row, the drag target starts only 4px after the description, and fixed-width actions/captions do not fit very narrow property rows. A medium 850px viewport also scales the full desktop below the readable text floor.

## Direction and plan

Keep the current visual identity and public API. Use one measured property layout for captions, descriptions and input fields: 16px horizontal padding, 12px vertical padding, 24px between text and inline fields, 12px before stacked fields, and at least 8px between descriptions and slider drag targets. Standard controls use a 32px visual height; rows grow for wrapped names/descriptions. Sliders get a distinct header, drag lane and endpoint lane, with bottom padding before the next control. Clip content at row/field boundaries as a final containment measure, not as a replacement for sizing.

Fields retain a common right edge and adapt their widths to available space. Long numeric text stays in a padded, clipped value field; narrow rows stack fields below full-width captions. Hide optional section tags when space is insufficient. Preserve 14px property names and 12px descriptions. Expand the desktop height from 660 to 688 to keep the ordinary Overview content visible with the new spacing; compact viewports still scroll. Use the compact layout when the full desktop cannot fit rather than scaling readable controls down unnecessarily.

1. Add four real Roblox regressions for safe slider lanes, narrow containment, wrapped descriptions and readable medium viewports. Run them against v0.4.5 to observe RED.
2. Add a small PropertyLayout module and apply its placement to Section and the four controls. Numeric fields gain a clipped padding container. Keep values, callbacks, pointer updates, popover ownership and cleanup unchanged.
3. Run the complete suite, inspect desktop/compact layouts and long content, and measure interaction rectangles across pages. Exercise real inputs, page changes and live resizing. Fix any observed defect, document results, regenerate the standalone pilot and push the existing draft PR.

## Validation

The four initial regressions failed against v0.4.5 (38/42), then passed with measured placement (42/42). A narrow-popover check subsequently reproduced text escaping the menu; caption/empty-state widths now follow the menu, with a bounded 180px minimum for narrow selectors. This went RED 42/43 to GREEN 43/43.

Independent read-only review identified value-dependent slider reflow at a stacking breakpoint: changing 0 to 100000000 with a suffix moved the drag lane by 44px. A new regression reproduced this. The field now reserves the complete formatted range/suffix width once, including fractional precision, and stays stable while values change. The reviewer also noted missing narrow-toggle coverage; the containment case now includes the actual state label and switch rather than treating the toggle's whole-row hit target as a small field.

The real geometry audit exposed another issue below the visible portion of a hidden page. Roblox deferred AbsoluteSize updates, leaving an offscreen action caption 216px wide inside a newly narrowed 196px row. Its regression failed before the fix. Placement now uses known logical page/section dimensions, and resize/tab activation eagerly refresh every row, including clipped descendants. The final unchanged expectations pass **45/45**, zero failures, in Roblox/Potassium PID 27324 (console summary sequence 1450). The two intentional callback-error warnings remain expected. Build/check and whitespace checks pass.

The final geometry audit checks every one of the 15 demo controls at 1920 x 1080, 1132 x 720, 900 x 720, 640 x 360, 420 x 700 and 320 x 500: **90 control layouts pass** containment, caption fit and text/field/drag-lane separation. This includes every page and controls below the visible fold. Scale remains 1 through the first five sizes, and 0.9 at the smallest. The ordinary Overview fits the 612px desktop workspace; slider endpoint labels now retain 12px below them.

Live engine mouse events dragged the slider to 76 and released the pointer. The nested value box accepted real GUI focus; editing its actual TextBox to 42 and committing with an engine Enter event updated the value to 42%. Dropdown selection changed only its own value to Smooth, the primary action completed, the toggle changed independently, and Restore reset the defaults. Key-code-only attempts to insert numeric characters did not enter text in this client's virtual-input path; the successful value-editor check assigns the TextBox text after focus settles and uses the real Enter/FocusLost path. This does not claim physical keyboard/touch/gamepad verification.

Native screenshots were inspected at desktop and compact dimensions. Standard fields align on the right edge, long captions wrap, narrow fields stack, and section tags hide when needed. The desktop viewport, Overview and default preview values were restored afterward. The v0.4.5 shadow and existing motion are preserved. No gameplay behavior was added.
