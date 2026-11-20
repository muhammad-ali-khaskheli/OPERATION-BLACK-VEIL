# OPERATION: BLACK VEIL
Godot 4 mobile-first single-player FPS campaign prototype. This repository is separate from PetroMobile.

## Mission 01 — The Awakening
Playable greybox night-infiltration arena featuring:
- First-person movement, mouse look, sprint, jump and aim-down-sights.
- Automatic rifle fire, magazine/reserve ammo and timed reload.
- Six hostile AI units that pursue and attack the player.
- Health, ammunition and mission-objective HUD.
- On-screen touch controls and right-side touch look for Android.
- Procedurally assembled industrial compound; no external assets required.

## Requirements
Godot 4.3 or later. Compatibility renderer is selected for broad Android support.

## Run
1. Clone or download this repository.
2. Open project.godot in Godot 4.
3. Press F5 to run the main scene.

Desktop: WASD move, mouse look, left mouse fire, right mouse aim, Shift sprint, Space jump, R reload, Esc release mouse.
Android: directional buttons move; drag the right side to look; use FIRE, AIM, RELOAD, SPRINT and JUMP buttons.

## Roadmap
1. Replace greybox geometry and procedural weapon with authored optimized assets.
2. Add mission scripting, squad radio, checkpoints and cinematics.
3. Add weapon selection, recoil tuning, enemy cover/navigation and difficulty.
4. Profile on target Android devices and create signed APK/AAB builds.

This is an early playable prototype, not a finished AAA game. Android performance, touch ergonomics and gameplay balance require real-device testing.
