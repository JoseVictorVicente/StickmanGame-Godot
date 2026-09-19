#!/usr/bin/env python3
"""Parse Stickman Idle structured game logs for assisted testing."""

from __future__ import annotations

import argparse
import json
import sys
import time
from typing import Any

EVENT_PREFIX = "[EVENT] "
EXPECTED_SAVE_VERSION = 6


def parse_line(line: str) -> dict[str, Any] | None:
    line = line.strip()
    if not line.startswith(EVENT_PREFIX):
        return None
    payload = line[len(EVENT_PREFIX) :]
    try:
        return json.loads(payload)
    except json.JSONDecodeError:
        return None


def read_events_from_stdin(timeout: float) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    deadline = time.time() + timeout if timeout > 0 else None
    while True:
        if deadline is not None and time.time() > deadline:
            break
        line = sys.stdin.readline()
        if line == "":
            if deadline is None:
                break
            if time.time() >= deadline:
                break
            time.sleep(0.05)
            continue
        event = parse_line(line)
        if event is not None:
            events.append(event)
    return events


def read_events_from_file(path: str) -> list[dict[str, Any]]:
    events: list[dict[str, Any]] = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            event = parse_line(line)
            if event is not None:
                events.append(event)
    return events


def validate(events: list[dict[str, Any]], expect_combat: bool) -> list[str]:
    failures: list[str] = []
    saw_boot = False
    saw_attack = False
    saw_hit = False
    saw_death = False
    saw_gold = False
    engine_errors = 0
    warnings = 0

    for event in events:
        name = str(event.get("event", ""))
        level = str(event.get("level", ""))
        data = event.get("data", {})

        if name == "system.boot":
            saw_boot = True
        if name == "combat.hero_attack":
            saw_attack = True
        if name == "combat.enemy_hit":
            saw_hit = True
            hp = data.get("hp")
            if hp is not None and int(hp) < 0:
                failures.append("hp_non_negative: enemy hp < 0")
        if name == "combat.enemy_died":
            saw_death = True
        if name == "progression.gold_gained":
            amount = data.get("amount", 0)
            if int(amount) < 0:
                failures.append("gold_consistency: negative gold_gained")
            saw_gold = True
        if name == "engine.error":
            engine_errors += 1
        if name == "engine.warning":
            warnings += 1
        if name == "save.loaded":
            version = data.get("migrated_from", data.get("version"))
            if version is not None and int(version) > EXPECTED_SAVE_VERSION:
                failures.append(
                    f"save_version_match: migrated_from {version} > {EXPECTED_SAVE_VERSION}"
                )
        if name.startswith("invariant.") and data.get("ok") is False:
            failures.append(f"invariant failed: {name} {data}")

    if not saw_boot:
        failures.append("boot_happened: missing system.boot")
    if engine_errors > 0:
        failures.append(f"no_engine_errors: found {engine_errors}")
    if expect_combat:
        if not saw_attack:
            failures.append("combat_loop_ran: missing combat.hero_attack")
        if not saw_hit:
            failures.append("combat_loop_ran: missing combat.enemy_hit")
        if not saw_death:
            failures.append("combat_loop_ran: missing combat.enemy_died")
        if not saw_gold:
            failures.append("combat_loop_ran: missing progression.gold_gained")

    return failures


def summarize(events: list[dict[str, Any]], failures: list[str]) -> dict[str, Any]:
    run_id = ""
    if events:
        run_id = str(events[0].get("run_id", ""))
    errors = sum(1 for e in events if e.get("event") == "engine.error")
    warnings = sum(1 for e in events if e.get("event") == "engine.warning")
    return {
        "passed": len(failures) == 0,
        "events_total": len(events),
        "errors": errors,
        "warnings": warnings,
        "failures": failures,
        "run_id": run_id,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Parse Stickman Idle game event logs")
    parser.add_argument("--file", help="Path to JSONL log file")
    parser.add_argument("--stdin", action="store_true", help="Read events from stdin")
    parser.add_argument("--watch", action="store_true", help="Read stdin until timeout")
    parser.add_argument("--timeout", type=float, default=0.0, help="Watch timeout seconds")
    parser.add_argument("--expect-boot", action="store_true", help="Require system.boot event")
    parser.add_argument("--expect-combat", action="store_true", help="Require combat loop events")
    args = parser.parse_args()

    if args.file:
        events = read_events_from_file(args.file)
    elif args.stdin or args.watch:
        timeout = args.timeout if args.watch else 0.0
        events = read_events_from_stdin(timeout)
    else:
        events = read_events_from_stdin(0.0)

    failures = validate(events, expect_combat=args.expect_combat)
    if args.expect_boot and not any(e.get("event") == "system.boot" for e in events):
        if "boot_happened: missing system.boot" not in failures:
            failures.append("boot_happened: missing system.boot")

    result = summarize(events, failures)
    print(json.dumps(result))
    if not events and (args.stdin or args.watch):
        return 3
    if any("parse" in f for f in failures):
        return 2
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
