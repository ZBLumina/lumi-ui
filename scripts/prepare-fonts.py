#!/usr/bin/env python3
"""Prepare Lumi's offline static TTFs; writes only assets/fonts/.

Install: python -m pip install fonttools==4.60.1
Build:   python scripts/prepare-fonts.py
Check:   python scripts/prepare-fonts.py --check
Rebuild without writing, then compare every byte:
         python scripts/prepare-fonts.py --check-reproducible

Variable source binaries are downloaded into memory, not shipped with the assets.
All upstream files are pinned by commit AND SHA-256. Comfortaa is copied from
the official upstream STATIC font without modification. No runtime downloads.
"""

from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
from io import BytesIO
import json
from pathlib import Path
import sys
from urllib.parse import quote
from urllib.request import Request, urlopen

try:
    import fontTools
    from fontTools import subset
    from fontTools.otlLib.optimize.gpos import compact
    from fontTools.pens.ttGlyphPen import TTGlyphPen
    from fontTools.ttLib import TTFont
    from fontTools.ttLib.sfnt import calcChecksum
    from fontTools.varLib.instancer import instantiateVariableFont
except ImportError:
    raise SystemExit("Install the build dependency: python -m pip install fonttools==4.60.1")


FONTTOOLS_VERSION = "4.60.1"
UPSTREAM_COMMIT = "6c1dbe27dcf7d817d4b62cec033ba77fa8e2a5ec"
UPSTREAM_REPOSITORY = "https://github.com/google/fonts"
COMFORTAA_STATIC_COMMIT = "2a87ac6f6ea3495150bfa00d0c0fb53dd0a2f11b"
COMFORTAA_STATIC_REPOSITORY = "https://github.com/googlefonts/comfortaa"
ASSETS = Path(__file__).resolve().parents[1] / "assets" / "fonts"

# Latin, Extended A/B/C/D/E and Additional; combining marks; spacing modifiers;
# punctuation, currencies, arrows, math and UI symbols. Keep the intersection
# with each source's cmap, not invented outlines or unrelated CJK glyphs.
UNICODE_RANGES = (
    (0x0020, 0x024F), (0x02B0, 0x036F), (0x1E00, 0x1EFF),
    (0x2000, 0x23FF), (0x2500, 0x27BF), (0x2C60, 0x2C7F),
    (0xA720, 0xA7FF), (0xAB30, 0xAB6F), (0xFE20, 0xFE2F),
    (0xFFFD, 0xFFFD),
)
CODEPOINTS = {cp for first, last in UNICODE_RANGES for cp in range(first, last + 1)}
REQUIRED_TEXT = "¡¿ÁÉÍÓÚÜÑáéíóúüñ—×\u2009"
UI_TEXT = "—–×÷−…‘’“”«»•·°©®™€£¥←↑→↓↔↕↗↘↙↖✓✕▸▾\u2009"
VARIATION_TABLES = {"fvar", "gvar", "avar", "HVAR", "VVAR", "MVAR", "cvar"}
LAYOUT_FEATURES = ["calt", "ccmp", "clig", "kern", "liga", "locl", "mark", "mkmk", "rlig"]

# Hashes cover the exact upstream bytes, including upstream newline conventions.
SOURCES = (
    {
        "family": "Fredoka", "directory": "fredoka",
        "font": "Fredoka[wdth,wght].ttf",
        "hashes": {
            "font": "2ba02e68b152868aef9ba28e24b3648c7d457fe6f25c761f2c2c53fb61a73fc8",
            "OFL.txt": "5c9e7eee5c6b25f4b05b8d53b2e470ea4962f9ced742d044a98f7d95d1375bab",
            "METADATA.pb": "17f260d0faf7c588c9331a9a1b720b55c2b871563423f42704c8cbb0953a574a",
        },
        "instances": [(600, "SemiBold", "Fredoka-SemiBold.ttf")],
    },
    {
        "family": "Nunito Sans", "directory": "nunitosans",
        "font": "NunitoSans[YTLC,opsz,wdth,wght].ttf",
        "hashes": {
            "font": "f934d7142fb4784bf828da485b7dcbd90c0c80d514e9d49a5da0ed3a1ae2491d",
            "OFL.txt": "efbb0c9e864cef973982d9a17567e6be5c3d1759695574586f3f18c7ecca064b",
            "METADATA.pb": "b60c93a2cdadb477316d22d22c8d43fa957899a4e4fe75cbb2b9e39e03c5e96e",
        },
        "instances": [(400, "Regular", "NunitoSans-Regular.ttf"), (500, "Medium", "NunitoSans-Medium.ttf")],
    },
    {
        "family": "Montserrat", "directory": "montserrat",
        "font": "Montserrat[wght].ttf",
        "hashes": {
            "font": "0f7b311b2f3279e4eef9b2f968bcdbab6e28f4daeb1f049f4f278a902bcd82f7",
            "OFL.txt": "8b7141c03fa4f8d44e6345d5d4931709290f0f67875e452e95ac1fd3a027802e",
            "METADATA.pb": "c48dbcaee013b8f6a33e7e6a79191adbf098a36839367d9750598594ff664e5f",
        },
        "instances": [(500, "Medium", "Montserrat-Medium.ttf")],
    },
    {
        "family": "Comfortaa", "directory": "comfortaa",
        "font": "Comfortaa-SemiBold.ttf", "unmodified_static": True,
        "font_url": f"https://raw.githubusercontent.com/googlefonts/comfortaa/{COMFORTAA_STATIC_COMMIT}/fonts/TTF/Comfortaa-SemiBold.ttf",
        "license_url": f"https://raw.githubusercontent.com/googlefonts/comfortaa/{COMFORTAA_STATIC_COMMIT}/OFL.txt",
        "hashes": {
            "font": "18cf25ac2e86f2e4edefb2f5f4d3d9b309629578a4c4c3196a2e556474d8e692",
            "OFL.txt": "bc85bae0b512b799bbfb2b916e4d0a34cfd963d09778cd783e248b479e67760a",
            "METADATA.pb": "70de3bdcdbe33269ad4e584eaa8514ff5e3359307edd534addfdbc199262a539",
        },
        "instances": [(600, "SemiBold", "Comfortaa-SemiBold.ttf")],
    },
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=True, indent=2, sort_keys=True) + "\n").encode("utf-8")


def unicode_ranges(codepoints: set[int]) -> list[str]:
    result = []
    for cp in sorted(codepoints):
        if result and cp == result[-1][1] + 1:
            result[-1][1] = cp
        else:
            result.append([cp, cp])
    return [f"U+{first:04X}" if first == last else f"U+{first:04X}-{last:04X}" for first, last in result]


def source_url(source: dict, name: str) -> str:
    if name == "font" and "font_url" in source:
        return source["font_url"]
    if name == "OFL.txt" and "license_url" in source:
        return source["license_url"]
    filename = source["font"] if name == "font" else name
    return f"https://raw.githubusercontent.com/google/fonts/{UPSTREAM_COMMIT}/ofl/{source['directory']}/{quote(filename)}"


def download(item: tuple[dict, str]) -> tuple[str, str, bytes]:
    source, name = item
    request = Request(source_url(source, name), headers={"User-Agent": "Lumi-static-font-preparation/1"})
    with urlopen(request, timeout=30) as response:
        content = response.read()
    require(sha256(content).hexdigest() == source["hashes"][name], f"Upstream hash mismatch: {source['family']} {name}")
    return source["family"], name, content


def instance_names(font: TTFont, family: str, style: str, filename: str) -> None:
    # Keep family identity, copyright, license, designer and version metadata.
    # Name the frozen weight, rather than the source variable font's base weight
    # or Nunito Sans's redundant default 'Normal' axis labels.
    postscript = Path(filename).stem
    values = {
        1: family if style == "Regular" else f"{family} {style}",
        2: "Regular", 4: f"{family} {style}", 6: postscript,
        16: family, 17: style,
        3: f"{font['name'].getDebugName(5)};LumiStatic;{postscript}",
    }
    for name_id, value in values.items():
        for record in list(font["name"].names):
            if record.nameID == name_id:
                font["name"].setName(value, name_id, record.platformID, record.platEncID, record.langID)
        font["name"].setName(value, name_id, 3, 1, 0x409)
    # A variation PostScript prefix has no meaning in a static font.
    font["name"].removeNames(nameID=25)


def ensure_thin_space(font: TTFont) -> list[dict]:
    if 0x2009 in font.getBestCmap():
        return []
    name = "uni2009"
    require(name not in font.getGlyphOrder(), "Thin-space glyph name collision")
    order = font.getGlyphOrder() + [name]
    advance = round(font["head"].unitsPerEm / 5)
    font["glyf"][name] = TTGlyphPen(None).glyph()
    font["hmtx"].metrics[name] = (advance, 0)
    font.setGlyphOrder(order)
    for table in font["cmap"].tables:
        if table.isUnicode() and table.format != 14:
            table.cmap[0x2009] = name
    return [{"codepoint": "U+2009", "description": "Empty thin-space glyph, 0.2 em advance", "advance_units": advance}]


def validate_font(data: bytes, family: str, weight: int, style: str, filename: str, *, unmodified_sha256: str | None = None) -> dict:
    require(data[:4] == b"\x00\x01\x00\x00", f"Not a TrueType sfnt: {filename}")
    require(calcChecksum(data) == 0xB1B0AFBA, f"Invalid whole-font checksum: {filename}")
    if unmodified_sha256:
        require(sha256(data).hexdigest() == unmodified_sha256, f"Official static font was modified: {filename}")
    with TTFont(BytesIO(data), checkChecksums=2, recalcTimestamp=False) as font:
        font.ensureDecompiled()  # Also strictly checks every sfnt table checksum.
        require(not VARIATION_TABLES.intersection(font.keys()), f"Variable table remains: {filename}")
        require(font["OS/2"].usWeightClass == weight, f"Wrong weight: {filename}")
        require(font["OS/2"].usWidthClass == 5, f"Wrong width: {filename}")
        require(font["post"].italicAngle == 0, f"Unexpected italic: {filename}")
        require(font["name"].getDebugName(16) == family, f"Wrong family: {filename}")
        require(font["name"].getDebugName(17) == style, f"Wrong subfamily: {filename}")
        require(font["name"].getDebugName(6) == Path(filename).stem, f"Wrong PostScript name: {filename}")
        for name_id in (0, 13, 14):
            require(bool(font["name"].getDebugName(name_id)), f"Missing legal name ID {name_id}: {filename}")
        cmap = font.getBestCmap()
        # The official Comfortaa static must remain byte-identical, including
        # its lack of U+2009. Never patch its glyphs, names or metadata.
        required_text = REQUIRED_TEXT.replace("\u2009", "") if unmodified_sha256 else REQUIRED_TEXT
        missing = sorted({ord(char) for char in required_text} - cmap.keys())
        require(not missing, f"Required Spanish/UI glyphs missing in {filename}: {unicode_ranges(set(missing))}")
        require(set(cmap.values()) <= set(font.getGlyphOrder()), f"Invalid cmap references: {filename}")
        for name in font.getGlyphOrder():
            font["glyf"][name].getCoordinates(font["glyf"])
        thin = cmap.get(0x2009)
        if thin:
            require(font["glyf"][thin].numberOfContours == 0, f"Thin space has an outline: {filename}")
            require(font["hmtx"][thin][0] > 0, f"Thin space has no advance: {filename}")
        return {
            "bytes": len(data), "sha256": sha256(data).hexdigest(),
            "glyph_count": len(font.getGlyphOrder()), "unicode_count": len(cmap),
            "unicode_ranges": unicode_ranges(set(cmap)),
            "ui_available": unicode_ranges({ord(char) for char in UI_TEXT if ord(char) in cmap}),
            "ui_unavailable_upstream": unicode_ranges({ord(char) for char in UI_TEXT if ord(char) not in cmap}),
            "thin_space_advance_units": font["hmtx"][thin][0] if thin else None,
            "units_per_em": font["head"].unitsPerEm,
        }


def prepare() -> dict[str, bytes]:
    jobs = [(source, name) for source in SOURCES for name in source["hashes"]]
    with ThreadPoolExecutor(max_workers=4) as pool:
        downloaded = {(family, name): content for family, name, content in pool.map(download, jobs)}
    files = {}
    manifest = {
        "schema_version": 1, "upstream_repository": UPSTREAM_REPOSITORY,
        "upstream_commit": UPSTREAM_COMMIT, "fonttools_version": FONTTOOLS_VERSION,
        "subset_ranges": unicode_ranges(CODEPOINTS), "layout_features": LAYOUT_FEATURES,
        "hinting_preserved": True, "gpos_compaction_level": 9,
        "timestamps": "Original source head.created/head.modified retained; no wall-clock values",
        "reserved_font_name_notice": "Comfortaa declares a Reserved Font Name. Its official upstream static SemiBold 600 is distributed byte-for-byte unchanged, with the original OFL, names, glyphs and metadata. No local subsetting, instancing, renaming, thin-space addition or reserialization is applied to Comfortaa.",
        "sources": [], "fonts": [],
    }
    for source in SOURCES:
        family = source["family"]
        slug = family.replace(" ", "")
        record = {"family": family, "files": []}
        for name in source["hashes"]:
            content = downloaded[family, name]
            path = None
            if name == "OFL.txt":
                path = f"licenses/{slug}-OFL.txt"
            elif name == "METADATA.pb":
                path = f"upstream/{slug}.METADATA.pb"
            if path:
                files[path] = content
            record["files"].append({"kind": name, "url": source_url(source, name), "sha256": source["hashes"][name], "bytes": len(content), "local_path": path})
        if source.get("unmodified_static"):
            record.update(repository=COMFORTAA_STATIC_REPOSITORY, commit=COMFORTAA_STATIC_COMMIT, distribution="unmodified-upstream-static")
            manifest["sources"].append(record)
            for weight, style, filename in source["instances"]:
                content = downloaded[family, "font"]
                validation = validate_font(content, family, weight, style, filename, unmodified_sha256=source["hashes"]["font"])
                files[filename] = content  # Copy the official bytes; do not save through TTFont.
                manifest["fonts"].append({"file": filename, "family": family, "weight": weight, "style": style, "axes": {}, "additions": [], "processing": "unmodified-upstream-static", "source_commit": COMFORTAA_STATIC_COMMIT, "subset_applied": False, **validation})
            continue
        with TTFont(BytesIO(downloaded[family, "font"]), recalcTimestamp=False) as original:
            defaults = {axis.axisTag: axis.defaultValue for axis in original["fvar"].axes}
            expected_cmap = set(original.getBestCmap()) & CODEPOINTS
            record["axis_defaults"] = defaults
        manifest["sources"].append(record)
        for weight, style, filename in source["instances"]:
            axes = {**defaults, "wght": weight}
            with TTFont(BytesIO(downloaded[family, "font"]), recalcTimestamp=False) as font:
                instantiateVariableFont(font, axes, inplace=True, updateFontNames=True)
                instance_names(font, family, style, filename)
                additions = ensure_thin_space(font)
                options = subset.Options()
                options.name_IDs = ["*"]
                options.name_languages = ["*"]
                options.name_legacy = True
                options.notdef_outline = True
                options.layout_features = LAYOUT_FEATURES
                options.recalc_timestamp = False
                options.harfbuzz_repacker = False  # Avoid optional installed-tool differences.
                subsetter = subset.Subsetter(options=options)
                subsetter.populate(unicodes=CODEPOINTS)
                subsetter.subset(font)
                require(set(font.getBestCmap()) == expected_cmap | {0x2009}, f"Subset lost source coverage: {filename}")
                compact(font, 9)  # Lossless class-kerning packing; preserves pair values.
                buffer = BytesIO()
                font.save(buffer, reorderTables=True)
            content = buffer.getvalue()
            validation = validate_font(content, family, weight, style, filename)
            files[filename] = content
            manifest["fonts"].append({"file": filename, "family": family, "weight": weight, "style": style, "axes": axes, "additions": additions, **validation})
    manifest["family_ttf_bytes"] = {
        source["family"]: sum(font["bytes"] for font in manifest["fonts"] if font["family"] == source["family"])
        for source in SOURCES
    }
    files["manifest.json"] = json_bytes(manifest)
    return files


def check() -> dict:
    manifest = json.loads((ASSETS / "manifest.json").read_bytes())
    require(manifest["upstream_commit"] == UPSTREAM_COMMIT, "Manifest commit does not match script")
    require(manifest["fonttools_version"] == FONTTOOLS_VERSION, "Manifest tool version does not match script")
    expected = {filename: (source, weight, style) for source in SOURCES for weight, style, filename in source["instances"]}
    require({font["file"] for font in manifest["fonts"]} == set(expected), "Manifest does not contain exactly the five expected TTFs")
    for font in manifest["fonts"]:
        filename = font["file"]
        source, weight, style = expected[filename]
        official_hash = source["hashes"]["font"] if source.get("unmodified_static") else None
        measured = validate_font((ASSETS / filename).read_bytes(), source["family"], weight, style, filename, unmodified_sha256=official_hash)
        require(all(font[key] == value for key, value in measured.items()), f"Validation/manifest mismatch: {filename}")
        if official_hash:
            require(font["processing"] == "unmodified-upstream-static" and not font["additions"] and not font["subset_applied"], "Incorrect official-static manifest policy")
    for source in SOURCES:
        slug = source["family"].replace(" ", "")
        for name, path in (("OFL.txt", f"licenses/{slug}-OFL.txt"), ("METADATA.pb", f"upstream/{slug}.METADATA.pb")):
            require(sha256((ASSETS / path).read_bytes()).hexdigest() == source["hashes"][name], f"Upstream metadata/license mismatch: {path}")
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--check", action="store_true", help="Validate shipped assets and metadata offline; do not write")
    mode.add_argument("--check-reproducible", action="store_true", help="Rebuild from pinned upstream files and compare every byte; do not write")
    args = parser.parse_args()
    require(fontTools.__version__ == FONTTOOLS_VERSION, f"Use fonttools=={FONTTOOLS_VERSION}; found {fontTools.__version__}")
    if not args.check:
        files = prepare()
        for path, content in files.items():
            target = ASSETS / path
            if args.check_reproducible:
                require(target.read_bytes() == content, f"Reproduction mismatch: {path}")
            else:
                if not target.exists() or target.read_bytes() != content:
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(content)
    manifest = check()
    for font in manifest["fonts"]:
        print(f"{font['file']}: weight={font['weight']}, bytes={font['bytes']}, glyphs={font['glyph_count']}, sha256={font['sha256']}")
    print("PASS: static TTFs, checksums, weights, names, Spanish, licenses and metadata")
    print("PASS: Comfortaa matches official static SHA-256; U+2009 remains absent upstream; other faces retain thin space")
    if args.check_reproducible:
        print("PASS: all generated files reproduce byte-for-byte")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        sys.exit(f"Font preparation failed: {error}")
