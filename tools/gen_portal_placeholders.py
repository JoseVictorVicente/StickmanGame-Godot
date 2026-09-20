"""Generate generic portal UI placeholders in sprites/ui/worlds/.

Replace briefing_dim_*.png and trail_dim_*.png with final art (same filenames).
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "sprites" / "ui" / "worlds"

def _brighten(r: int, g: int, b: int, lift: int = 48) -> tuple[int, int, int]:
    return min(255, r + lift), min(255, g + lift), min(255, b + lift)


THEMES: list[tuple[str, int, int, object]] = [
    (
        "briefing_dim_1",
        280,
        140,
        lambda x, y, w, h: _brighten(int(20 + 40 * (x / w)), int(55 + 35 * (y / h)), int(25 + 20 * (1 - x / w))),
    ),
    (
        "briefing_dim_2",
        280,
        140,
        lambda x, y, w, h: _brighten(int(35 + 25 * (x / w)), int(20 + 30 * (y / h)), int(45 + 20 * (1 - y / h))),
    ),
    (
        "briefing_dim_3",
        280,
        140,
        lambda x, y, w, h: _brighten(int(120 + 50 * (x / w)), int(95 + 35 * (y / h)), int(45 + 15 * (1 - x / w))),
    ),
    (
        "briefing_dim_4",
        280,
        140,
        lambda x, y, w, h: _brighten(int(70 + 40 * (x / w)), int(110 + 30 * (y / h)), int(130 + 20 * (1 - y / h))),
    ),
    (
        "briefing_dim_5",
        280,
        140,
        lambda x, y, w, h: _brighten(int(90 + 40 * (x / w)), int(35 + 25 * (y / h)), int(25 + 15 * (1 - x / w))),
    ),
    (
        "trail_dim_1",
        768,
        1344,
        lambda x, y, w, h: _brighten(int(18 + 30 * (y / h)), int(40 + 25 * (x / w)), int(22 + 18 * (1 - y / h)), 36),
    ),
    (
        "trail_dim_2",
        768,
        1344,
        lambda x, y, w, h: _brighten(int(28 + 22 * (y / h)), int(24 + 20 * (x / w)), int(38 + 16 * (1 - y / h)), 36),
    ),
    (
        "trail_dim_3",
        768,
        1344,
        lambda x, y, w, h: _brighten(int(110 + 35 * (y / h)), int(88 + 30 * (x / w)), int(42 + 12 * (1 - y / h)), 36),
    ),
    (
        "trail_dim_4",
        768,
        1344,
        lambda x, y, w, h: _brighten(int(75 + 40 * (y / h)), int(105 + 28 * (x / w)), int(125 + 18 * (1 - y / h)), 36),
    ),
    (
        "trail_dim_5",
        768,
        1344,
        lambda x, y, w, h: _brighten(int(95 + 45 * (y / h)), int(38 + 22 * (x / w)), int(24 + 14 * (1 - y / h)), 36),
    ),
]


def _chunk(tag: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)


def write_png(path: Path, width: int, height: int, rgb_func) -> None:
    rows: list[bytes] = []
    for y in range(height):
        row = b"\x00"
        for x in range(width):
            r, g, b = rgb_func(x, y, width, height)
            row += bytes([min(255, max(0, r)), min(255, max(0, g)), min(255, max(0, b))])
        rows.append(row)
    compressed = zlib.compress(b"".join(rows), 9)
    with path.open("wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)))
        handle.write(_chunk(b"IDAT", compressed))
        handle.write(_chunk(b"IEND", b""))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, width, height, fn in THEMES:
        target = OUT / f"{name}.png"
        write_png(target, width, height, fn)
        print(f"wrote {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
