#!/usr/bin/env python3
"""Export combat catalog slices from skill_catalog_data.py for generate_skills.ps1."""

from __future__ import annotations

import json
from pathlib import Path

from skill_catalog_data import (
    ACTIVE_COOLDOWNS,
    ACTIVE_EFFECTS,
    ACTIVE_ID_OVERRIDES,
    ACTIVE_VFX,
    CATALOG,
    ICON_INNER_ONLY,
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "tools" / "skill_catalog_export.json"


def _validate_lengths() -> None:
    for class_id, groups in CATALOG.items():
        active_count = len(groups["active"])
        effects = ACTIVE_EFFECTS.get(class_id, [])
        vfx = ACTIVE_VFX.get(class_id, [])
        if effects and len(effects) != active_count:
            raise ValueError(
                f"ACTIVE_EFFECTS['{class_id}'] has {len(effects)} entries, "
                f"expected {active_count} (CATALOG active count)"
            )
        if vfx and len(vfx) != active_count:
            raise ValueError(
                f"ACTIVE_VFX['{class_id}'] has {len(vfx)} entries, "
                f"expected {active_count} (CATALOG active count)"
            )


def main() -> None:
    _validate_lengths()
    payload = {
        "active_cooldowns": ACTIVE_COOLDOWNS,
        "active_id_overrides": ACTIVE_ID_OVERRIDES,
        "active_effects": ACTIVE_EFFECTS,
        "active_vfx": ACTIVE_VFX,
        "icon_inner_only": {key: sorted(value) for key, value in ICON_INNER_ONLY.items()},
    }
    OUT.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Exported skill catalog to {OUT}")


if __name__ == "__main__":
    main()
