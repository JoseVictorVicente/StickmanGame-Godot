# Combat validation

## Headless

```powershell
& "D:\Desktop\Tudo\Godot\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" --headless --path "D:\Desktop\Tudo\Godot\Projetos\StickmanGame" -s res://tests/combat_simulator_test.gd
```

Covers: damage pipeline, horde chain, swarm contact, solo runner lane engage, `ENEMY_HIT_HERO`, spawn distance.

## Assisted logging

```powershell
powershell -ExecutionPolicy Bypass -File tools/run_assisted_check.ps1
```

After changes to `combat_controller.gd` or `main.gd` wiring.

## Manual overlay playtest

1. F5 — idle combat starts (world 1)
2. Wait for wave 1 kill → runner between waves
3. Confirm enemy approaches from right, does not overlap archer at engage
4. Open/close inventory — combat resumes
5. Stage 2 horde — multiple imps, swarm attacks after contact
