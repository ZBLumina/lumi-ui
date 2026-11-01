# v0.4.5 — panel shadow

The user reports that the shadow looks low quality. Inspection found a single flat, translucent rounded rectangle extending 6px beyond the sides and 9px below the shell. Its abrupt opacity boundary reads as a hard band.

## Scope and implementation

Replace that footprint with an antialiased native silhouette whose opacity falls off continuously. A broad ambient profile and a smaller contact profile share a neutral warm shadow token. A logistic falloff and alpha-over correction distribute opacity across 32 ambient and 12 contact samples; inset samples avoid a flat bottom band from the downward offset. This adds no downloaded image, executor file cache, perpetual update loop or input connection. The 44 static silhouette frames participate in the existing window fade and are destroyed with the root.

The transparent shadow container follows the shell using scale-based sizing, so Fit no longer writes a separate shadow rectangle size. Corners expand with the silhouette rather than stretching a bitmap. The status bar now respects the shell's bottom-right radius, avoiding a square corner over the rounded shadow.

Plan: inspect the real baseline, prototype on the game and a temporary neutral light backdrop, integrate the chosen falloff, rebuild, verify desktop/compact/scaled motion and the existing integration suite, restore the normal pilot, document and push to the existing draft PR. Keep all layout, readable type, control APIs and interaction behavior otherwise unchanged. No tests that merely restate shadow colors/coordinates are added for this reversible presentation fix.

## Validation

Verified in Roblox through Potassium, PID 27324. Native screenshots were inspected over the game and a temporary light neutral backdrop to expose contour seams, the outer falloff and the bottom-right join. The flat rectangular band is replaced by a gradual shadow; the final corner now follows the same radius as the shell. The light backdrop is a temporary review fixture with explicit cleanup and a timed failsafe.

At a simulated 640 x 360 available viewport, the shadow container follows the 608 x 328 shell; at 75% UI scale, both measure 456 x 246. A temporary window's shadow opacity increases during Close and its root/runtime are released after the transition. These are observed live engine checks, not claims of physical-device or performance benchmarking. The normal desktop pilot is restored after inspection.

The unchanged real Roblox suite passes **38/38**, zero failures (console summary sequence 1023). The two intentional callback-error warnings are expected. Build/check and whitespace checks pass. Final source review confirms there are no extra input listeners, texture-loading dependencies or cleanup paths in the shadow component. No unrelated controls or layout were changed.
