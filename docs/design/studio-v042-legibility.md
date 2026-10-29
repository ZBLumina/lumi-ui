# v0.4.2 — text visibility

The user reported that some text was difficult to see after the finesse pass. Source inspection found 8–9px metadata and low-emphasis text at RGB(149,148,136). The correction keeps the current visual composition and interaction API.

- Primary text: RGB(245,244,237); secondary: (211,210,199); muted: (185,184,172).
- Shared text labels have a minimum nominal size of 11px. Main property names are 14px GothamMedium; descriptions are 12px. Dropdown labels/actions are 13px; inspector descriptions and metadata are 12px.
- The small value-caption field was enlarged to hold its new size. No controls, callbacks, values, mounting behavior or compact reflow logic changed.

Computed opaque muted-text contrast on the hover surface (50,51,46) increased from 4.17:1 to 6.38:1. Secondary text on the section surface is 10.39:1. These color calculations supplement the actual Roblox screenshot review; they do not establish device-wide accessibility compliance or account for font rasterization.

Actual Potassium PID 7740 execution loaded v0.4.2 successfully. The desktop render was visually inspected; a live scan reported 111 nonempty text objects, zero below 11px, and no overflowing inspector text for the displayed Intensity state. All 27 existing real Roblox runtime assertions passed unchanged; the two intentional callback-error warnings remained expected. Build, stale-output, Node syntax and whitespace checks passed.

Compact rendering was also visually inspected in a simulated 640 x 360 GUI viewport. Scale stayed 1; property names/descriptions remained 14/12px and fit the stacked rows. The normal desktop layout was restored afterward. Physical device testing was not part of this typography correction.
