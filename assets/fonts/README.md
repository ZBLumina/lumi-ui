# Lumi static font assets

These five local TrueType files are inputs for the parent bundle's embedded FontsData module. No font download is needed at runtime.

| File | Static weight | Frozen axes | Bytes |
| --- | --- | --- | ---: |
| Fredoka-SemiBold.ttf | 600 | wght=600, wdth=100 | 37,720 |
| NunitoSans-Regular.ttf | 400 | wght=400, wdth=100, opsz=12, YTLC=500 | 63,668 |
| NunitoSans-Medium.ttf | 500 | wght=500, wdth=100, opsz=12, YTLC=500 | 63,708 |
| Montserrat-Medium.ttf | 500 | wght=500 | 108,964 |
| Comfortaa-SemiBold.ttf | 600 | Official static; no variation axes | 140,476 |

All faces are upright and normal width. Nunito Sans's optical size, width and ascender settings are its upstream defaults; Fredoka's width is its upstream default. Nunito Sans totals 127,376 bytes across two weights. Montserrat is slightly above the preferred 100 KB target; coverage and kerning were retained instead of further trimming.

## Provenance and regeneration

Official source: [google/fonts at commit 6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec](https://github.com/google/fonts/tree/6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec).

Comfortaa is the exception: its **unmodified official static SemiBold 600** comes from [googlefonts/comfortaa at commit 2a87ac6f6ea3495150bfa00d0c0fb53dd0a2f11b](https://github.com/googlefonts/comfortaa/blob/2a87ac6f6ea3495150bfa00d0c0fb53dd0a2f11b/fonts/TTF/Comfortaa-SemiBold.ttf). The local file is the exact upstream 140,476-byte binary, SHA-256 `18cf25ac2e86f2e4edefb2f5f4d3d9b309629578a4c4c3196a2e556474d8e692`. It is not subset, instantiated, renamed, patched, optimized, or reserialized locally. Its original full character coverage, names, hinting, metadata and all tables are retained. The larger file size is intentional.

- `manifest.json` records every source URL/SHA-256, output SHA-256, weight, frozen axes, glyph coverage, additions, and byte count.
- `upstream/*.METADATA.pb` contains the exact official Google Fonts family metadata. Comfortaa's family metadata describes the Google Fonts variable source; the actual distributed static binary and its separate source commit are explicitly recorded in the manifest.
- `licenses/*-OFL.txt` contains each family's exact upstream SIL Open Font License 1.1, including copyright notices and original newline conventions.

From the repository root:

```sh
python -m pip install fonttools==4.60.1
python scripts/prepare-fonts.py
python scripts/prepare-fonts.py --check
python scripts/prepare-fonts.py --check-reproducible
```

The script pins both upstream commits and all twelve input hashes. It downloads source binaries into memory. For Fredoka, Nunito Sans and Montserrat, it freezes all variation axes, preserves source timestamps and legal metadata, and emits fonts with correct instance names. It preserves TrueType hinting and standard Latin shaping/kerning features, then losslessly compacts GPOS class kerning. Optional HarfBuzz repacking is explicitly disabled so installed optional libraries cannot change the result. Comfortaa bypasses that entire transformation path: the script copies the original official static bytes and requires its exact upstream SHA-256 during both preparation and offline validation. Only `assets/fonts/` is written, and files whose bytes already match are left untouched. `--check` works offline; `--check-reproducible` rebuilds from upstream and compares all generated files byte for byte without writing.

## Character coverage and checks

The four locally prepared subsets retain source glyphs in Latin, Latin Extended A/B/C/D/E and Additional, combining marks, spacing modifiers, punctuation, currencies, arrows, math and UI symbol ranges. They retain every source-supported codepoint in the declared ranges; no CJK coverage is requested. Original accent outlines and composite dependencies remain intact. Comfortaa retains its entire upstream static character set. All five faces include `ÁÉÍÓÚÜÑáéíóúüñ¡¿`, em dash and multiplication sign.

Fredoka receives a blank U+2009 glyph with a 0.2-em advance (200 units at 1000 units/em); its other outlines remain upstream-derived. Nunito Sans and Montserrat retain their original thin spaces. **The official Comfortaa static lacks U+2009 and remains unmodified.** The parent runtime must account for that missing character when using thin spaces for tracking; no glyph is added here. Arrows are retained where available upstream (Montserrat and Comfortaa); missing symbol outlines are not synthesized. See each font's `ui_available` and `ui_unavailable_upstream` entries in the manifest.

Validation checks the TrueType sfnt signature, global and every table checksum, absence of variation tables, exact OS/2 weights and normal width, upright angle, instance/family/PostScript names, legal metadata, every glyph's coordinates/composite references, cmap references, and required Spanish/UI characters. It checks the blank thin space's positive advance for the four prepared subsets, and exact official-source byte identity for Comfortaa. Loader behavior and real-client rendering belong to the parent integration.

## Comfortaa reserved name

Comfortaa's upstream license explicitly reserves the name **Comfortaa**. The distributed file is now the **unmodified official upstream static font**, accompanied by its exact original OFL and copyright notice. The earlier locally modified subset has been replaced. No renamed derivative is used, so this asset preserves the actual Comfortaa family and SemiBold 600 weight without invoking the modified-font naming restriction. Both preparation and offline checks reject any change to the upstream binary. Its matching OFL is fetched from the same upstream commit (SHA-256 `bc85bae0b512b799bbfb2b916e4d0a34cfd963d09778cd783e248b479e67760a`). See the [OFL FAQ on modified fonts and Reserved Font Names](https://openfontlicense.org/ofl-faq/). No publication is performed by this script.
