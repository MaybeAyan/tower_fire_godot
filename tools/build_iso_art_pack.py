from __future__ import annotations

import argparse
import json
import math
import shutil
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter


PROJECT_ROOT = Path(__file__).resolve().parents[1]
MAGENTA = (255, 0, 255)


UNIT_SPECS = [
    ("astra", "astra-isometric-actions.png", "astra-isometric-token.png", (61, 130, 224)),
    ("liora", "liora-isometric-actions.png", "liora-isometric-token.png", (108, 222, 174)),
    ("kael", "kael-isometric-actions.png", "kael-isometric-token.png", (244, 204, 101)),
    ("sword", "enemy-sword-isometric-actions.png", "enemy-sword-isometric-token.png", (232, 86, 99)),
    ("mage", "enemy-mage-isometric-actions.png", "enemy-mage-isometric-token.png", (117, 138, 255)),
    ("guard", "enemy-guard-isometric-actions.png", "enemy-guard-isometric-token.png", (148, 231, 220)),
    ("enemy_boss", "enemy-boss-isometric-actions.png", "enemy-boss-isometric-token.png", (244, 122, 66)),
]

CARD_SPECS = [
    ("strike", "iso-quick-slash.png", 0),
    ("lance", "iso-radiant-lance.png", 1),
    ("dash", "iso-step-command.png", 2),
    ("guard", "iso-guard-bloom.png", 3),
    ("engage", "iso-engage-crest.png", 4),
    ("heal", "iso-mend-light.png", 5),
]

TERRAIN_COLORS = {
    "floor": ((114, 181, 79), (64, 117, 56)),
    "wall": ((128, 142, 127), (74, 82, 78)),
    "pillar": ((148, 156, 148), (82, 88, 86)),
    "gate": ((174, 137, 82), (102, 72, 45)),
    "high": ((156, 198, 90), (102, 134, 60)),
    "holy": ((126, 230, 201), (62, 146, 136)),
    "fire": ((237, 117, 85), (132, 68, 52)),
    "marker": ((111, 184, 245), (50, 102, 154)),
}


def ensure_dirs() -> None:
    for rel in [
        "assets/art/source",
        "assets/art/tilesets",
        "assets/art/ui/isometric_tactics",
        "assets/art/unit_sheets",
        "assets/art/tokens",
        "assets/art/cards",
    ]:
        (PROJECT_ROOT / rel).mkdir(parents=True, exist_ok=True)


def copy_sources(style_path: Path, units_path: Path) -> tuple[Path, Path]:
    style_out = PROJECT_ROOT / "assets/art/source/generated-isometric-tactics-contact-sheet.png"
    units_out = PROJECT_ROOT / "assets/art/source/generated-isometric-units-contact-sheet.png"
    shutil.copy2(style_path, style_out)
    shutil.copy2(units_path, units_out)
    return style_out, units_out


def remove_magenta(image: Image.Image, threshold: int = 50) -> Image.Image:
    image = image.convert("RGBA")
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if abs(r - MAGENTA[0]) <= threshold and g <= threshold and abs(b - MAGENTA[2]) <= threshold:
                pixels[x, y] = (r, g, b, 0)
    return image


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def fit_on_canvas(image: Image.Image, size: tuple[int, int], scale: float = 0.92, align: str = "bottom") -> Image.Image:
    image = image.convert("RGBA")
    bbox = alpha_bbox(image)
    canvas = Image.new("RGBA", size, (0, 0, 0, 0))
    if bbox is None:
        return canvas
    cropped = image.crop(bbox)
    max_w = int(size[0] * scale)
    max_h = int(size[1] * scale)
    factor = min(max_w / cropped.width, max_h / cropped.height)
    target = (max(1, int(cropped.width * factor)), max(1, int(cropped.height * factor)))
    cropped = cropped.resize(target, Image.Resampling.LANCZOS)
    x = (size[0] - target[0]) // 2
    if align == "bottom":
        y = size[1] - target[1] - int(size[1] * 0.05)
    else:
        y = (size[1] - target[1]) // 2
    canvas.alpha_composite(cropped, (x, max(0, y)))
    return canvas


def draw_panel(size: tuple[int, int], corner: int = 22, alpha: int = 214, border: bool = True) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    shadow = (0, 6, 16, 95)
    fill = (17, 47, 70, alpha)
    inner = (58, 104, 130, 58)
    cyan = (180, 239, 255, 126)
    gold = (255, 222, 137, 172)
    draw.rounded_rectangle((6, 8, w - 4, h - 3), radius=corner, fill=shadow)
    draw.rounded_rectangle((2, 2, w - 3, h - 7), radius=corner, fill=fill)
    draw.rounded_rectangle((10, 10, w - 12, h - 17), radius=max(4, corner - 8), fill=inner)
    if border:
        draw.rounded_rectangle((2, 2, w - 3, h - 7), radius=corner, outline=cyan, width=3)
        draw.rounded_rectangle((12, 12, w - 14, h - 19), radius=max(4, corner - 10), outline=(230, 251, 255, 66), width=2)
        seg = min(w, h) * 0.22
        for sx, sy, ex, ey in [
            (12, 12, 12 + seg, 12),
            (12, 12, 12, 12 + seg),
            (w - 14, 12, w - 14 - seg, 12),
            (w - 14, 12, w - 14, 12 + seg),
            (12, h - 19, 12 + seg, h - 19),
            (12, h - 19, 12, h - 19 - seg),
            (w - 14, h - 19, w - 14 - seg, h - 19),
            (w - 14, h - 19, w - 14, h - 19 - seg),
        ]:
            draw.line((sx, sy, ex, ey), fill=gold, width=3)
    glow = image.filter(ImageFilter.GaussianBlur(5))
    return Image.alpha_composite(glow.point(lambda p: int(p * 0.45)), image)


def draw_diamond_tile(size: tuple[int, int], top: tuple[int, int, int], bottom: tuple[int, int, int], cliff: bool = False) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    cx = w // 2
    top_y = int(h * 0.10)
    mid_y = int(h * 0.38)
    bot_y = int(h * 0.74)
    left = int(w * 0.08)
    right = int(w * 0.92)
    diamond = [(cx, top_y), (right, mid_y), (cx, int(h * 0.66)), (left, mid_y)]
    draw.polygon(diamond, fill=(*top, 255))
    for i in range(10):
        t = i / 9.0
        color = tuple(int(top[j] * (1 - t) + bottom[j] * t) for j in range(3))
        y = int(top_y + (int(h * 0.66) - top_y) * t)
        inset = int(abs(t - 0.5) * w * 0.78)
        draw.line((left + inset // 2, y, right - inset // 2, y), fill=(*color, 34), width=1)
    draw.line(diamond + [diamond[0]], fill=(236, 252, 199, 128), width=2)
    draw.line((left, mid_y, cx, int(h * 0.66), right, mid_y), fill=(38, 73, 44, 120), width=2)
    if cliff:
        left_face = [(left, mid_y), (cx, int(h * 0.66)), (cx, bot_y), (left, int(h * 0.50))]
        right_face = [(right, mid_y), (cx, int(h * 0.66)), (cx, bot_y), (right, int(h * 0.50))]
        draw.polygon(left_face, fill=(75, 70, 62, 230))
        draw.polygon(right_face, fill=(54, 58, 58, 235))
        for x in range(left + 6, right, 15):
            draw.line((x, int(h * 0.47), x - 10, bot_y - 2), fill=(24, 30, 30, 78), width=1)
    return image


def draw_range(size: tuple[int, int], color: tuple[int, int, int], grid: bool = False, ring: bool = False) -> Image.Image:
    w, h = size
    image = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image, "RGBA")
    cx, cy = w // 2, h // 2
    diamond = [(cx, 8), (w - 8, cy), (cx, h - 8), (8, cy)]
    if ring:
        draw.line(diamond + [diamond[0]], fill=(*color, 245), width=7)
        draw.line([(cx, 17), (w - 17, cy), (cx, h - 17), (17, cy), (cx, 17)], fill=(255, 251, 204, 190), width=2)
    else:
        draw.polygon(diamond, fill=(*color, 72))
        draw.line(diamond + [diamond[0]], fill=(*color, 210), width=4)
        draw.line([(cx, 16), (w - 16, cy), (cx, h - 16), (16, cy), (cx, 16)], fill=(255, 255, 255, 74), width=1)
    if grid:
        for offset in range(-3, 4):
            x0 = cx + offset * 18
            draw.line((x0, 18, x0 + 60, cy), fill=(*color, 66), width=1)
            draw.line((x0, h - 18, x0 + 60, cy), fill=(*color, 66), width=1)
    glow = image.filter(ImageFilter.GaussianBlur(7))
    return Image.alpha_composite(glow.point(lambda p: int(p * 0.50)), image)


def build_tileset() -> None:
    tile_w, tile_h = 160, 112
    atlas = Image.new("RGBA", (tile_w * 8, tile_h * 6), (0, 0, 0, 0))
    keys = list(TERRAIN_COLORS.keys())
    for idx, key in enumerate(keys):
        x = idx % 8
        y = idx // 8
        top, bottom = TERRAIN_COLORS[key]
        tile = draw_diamond_tile((tile_w, tile_h), top, bottom, cliff=key in ["wall", "pillar", "gate"])
        draw = ImageDraw.Draw(tile, "RGBA")
        cx = tile_w // 2
        if key == "wall":
            draw.rectangle((cx - 22, 18, cx + 22, 52), fill=(126, 130, 122, 230))
            draw.line((cx - 22, 52, cx + 22, 52), fill=(34, 38, 39, 150), width=2)
        elif key == "pillar":
            draw.rounded_rectangle((cx - 16, 8, cx + 16, 55), radius=5, fill=(155, 158, 148, 235), outline=(76, 82, 80, 170), width=2)
        elif key == "gate":
            draw.rectangle((cx - 31, 18, cx + 31, 54), fill=(120, 86, 52, 230), outline=(242, 203, 117, 120), width=2)
        elif key == "high":
            draw.line((38, 35, 122, 35), fill=(255, 244, 186, 140), width=4)
        elif key == "holy":
            draw.ellipse((cx - 22, 26, cx + 22, 62), outline=(207, 255, 239, 210), width=4)
            draw.line((cx, 18, cx, 66), fill=(143, 255, 216, 170), width=2)
        elif key == "fire":
            draw.arc((cx - 28, 24, cx + 28, 68), 205, 500, fill=(255, 218, 107, 220), width=4)
        elif key == "marker":
            draw.ellipse((cx - 20, 28, cx + 20, 62), outline=(151, 239, 255, 210), width=3)
            draw.line((cx - 18, 45, cx + 18, 45), fill=(151, 239, 255, 140), width=2)
        atlas.alpha_composite(tile, (x * tile_w, y * tile_h))
    atlas.save(PROJECT_ROOT / "assets/art/tilesets/isometric-floating-tiles-v1.png")


def build_ui_assets() -> None:
    out = PROJECT_ROOT / "assets/art/ui/isometric_tactics"
    draw_panel((430, 520), 18, 218).save(out / "iso-status-panel.png")
    draw_panel((1120, 190), 20, 206).save(out / "iso-skill-dock.png")
    draw_panel((430, 110), 16, 210).save(out / "iso-objective-pill.png")
    draw_panel((470, 104), 16, 204).save(out / "iso-skill-card-frame.png")
    draw_panel((300, 72), 14, 210).save(out / "iso-small-button.png")
    draw_range((256, 128), (74, 172, 255), True).save(out / "iso-range-move.png")
    draw_range((256, 128), (255, 89, 82), True).save(out / "iso-range-attack.png")
    draw_range((256, 128), (255, 184, 72), True).save(out / "iso-range-danger.png")
    draw_range((256, 128), (255, 240, 165), False, True).save(out / "iso-range-selected.png")
    draw_range((256, 128), (255, 242, 168), False, True).save(out / "iso-selected-ring.png")


def build_background(style: Image.Image) -> None:
    bg = Image.new("RGBA", (1440, 900), (12, 29, 48, 255))
    crop = style.crop((0, 0, int(style.width * 0.58), int(style.height * 0.56))).convert("RGBA")
    crop = ImageEnhance.Color(crop).enhance(0.9)
    crop = crop.resize((980, 600), Image.Resampling.LANCZOS)
    crop.putalpha(190)
    bg.alpha_composite(crop, (58, 72))
    draw = ImageDraw.Draw(bg, "RGBA")
    for i in range(18):
        x = 80 + i * 76
        draw.line((x, 0, x - 420, 900), fill=(116, 196, 222, 18), width=2)
    for r in [900, 760, 620]:
        draw.ellipse((720 - r, 460 - r // 2, 720 + r, 460 + r // 2), outline=(128, 210, 255, 16), width=3)
    vignette = Image.new("L", bg.size, 0)
    vdraw = ImageDraw.Draw(vignette)
    vdraw.ellipse((-120, -110, 1560, 1030), fill=180)
    shade = Image.new("RGBA", bg.size, (0, 7, 16, 130))
    bg = Image.composite(bg, Image.alpha_composite(bg, shade), vignette)
    bg.convert("RGB").save(PROJECT_ROOT / "assets/art/battlefield-isometric-island.png", quality=95)


def crop_card_icons(style: Image.Image) -> None:
    w, h = style.size
    y0 = int(h * 0.74)
    y1 = int(h * 0.97)
    cell_w = w / 6.0
    for key, filename, index in CARD_SPECS:
        x0 = int(index * cell_w + cell_w * 0.13)
        x1 = int((index + 1) * cell_w - cell_w * 0.08)
        icon = style.crop((x0, y0, x1, y1)).convert("RGBA")
        icon = ImageEnhance.Contrast(icon).enhance(1.05)
        icon = fit_on_canvas(icon, (512, 512), 0.98, "center")
        panel = draw_panel((512, 512), 34, 232)
        panel.alpha_composite(icon)
        panel.save(PROJECT_ROOT / "assets/art/cards" / filename)


def crop_unit_cell(units: Image.Image, row: int, col: int) -> Image.Image:
    cell_w = units.width / 9.0
    cell_h = units.height / 7.0
    pad_x = cell_w * 0.06
    pad_y = cell_h * 0.04
    box = (
        int(col * cell_w + pad_x),
        int(row * cell_h + pad_y),
        int((col + 1) * cell_w - pad_x),
        int((row + 1) * cell_h - pad_y),
    )
    return remove_magenta(units.crop(box), threshold=58)


def build_unit_sheets(units: Image.Image) -> None:
    frame_map = [
        [0, 1, 2, 1],
        [0, 1, 2, 1],
        [3, 4, 5, 3],
        [4, 5, 6, 4],
        [6, 7, 6, 7],
        [8, 8, 8, 8],
    ]
    for row, (_, sheet_filename, token_filename, accent) in enumerate(UNIT_SPECS):
        sheet = Image.new("RGBA", (512, 768), (0, 0, 0, 0))
        for action_row, cols in enumerate(frame_map):
            for col_index, source_col in enumerate(cols):
                frame = crop_unit_cell(units, row, source_col)
                frame = fit_on_canvas(frame, (128, 128), 0.96, "bottom")
                sheet.alpha_composite(frame, (col_index * 128, action_row * 128))
        sheet.save(PROJECT_ROOT / "assets/art/unit_sheets" / sheet_filename)

        token = crop_unit_cell(units, row, 0)
        token = fit_on_canvas(token, (640, 640), 0.72, "center")
        ring = Image.new("RGBA", (640, 640), (0, 0, 0, 0))
        draw = ImageDraw.Draw(ring, "RGBA")
        draw.ellipse((62, 72, 578, 588), fill=(11, 27, 43, 188), outline=(*accent, 216), width=12)
        draw.ellipse((92, 102, 548, 558), outline=(255, 239, 178, 116), width=4)
        ring.alpha_composite(token)
        ring.save(PROJECT_ROOT / "assets/art/tokens" / token_filename)


def write_manifest(style_source: Path, units_source: Path) -> None:
    manifest = {
        "style": "bright fantasy isometric tactical RPG, generated with imagegen and postprocessed for Godot",
        "sources": {
            "style_contact_sheet": str(style_source.relative_to(PROJECT_ROOT)).replace("\\", "/"),
            "unit_contact_sheet": str(units_source.relative_to(PROJECT_ROOT)).replace("\\", "/"),
        },
        "tile_size": [160, 112],
        "unit_sheet": {
            "columns": 4,
            "rows": 6,
            "frame_size": [128, 128],
            "rows_contract": ["idle", "move", "attack", "skill", "hit", "defeat"],
        },
    }
    out = PROJECT_ROOT / "assets/art/ui/isometric_tactics/manifest.json"
    out.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--style", required=True, type=Path)
    parser.add_argument("--units", required=True, type=Path)
    args = parser.parse_args()

    ensure_dirs()
    style_source, units_source = copy_sources(args.style, args.units)
    style = Image.open(style_source).convert("RGBA")
    units = Image.open(units_source).convert("RGBA")
    build_background(style)
    build_tileset()
    build_ui_assets()
    crop_card_icons(style)
    build_unit_sheets(units)
    write_manifest(style_source, units_source)
    print("Built isometric art pack.")


if __name__ == "__main__":
    main()
