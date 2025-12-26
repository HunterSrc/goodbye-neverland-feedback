# Outstanding Tasks

## Core polish
- Hook up audio SFX (beat/hit/miss/damage, heart loss, spitter shot/impact) and assign streams in GameManager.
- “Carica” menu entry hidden until save/load flow exists.
- Title/subtitle cards: fade-only on death reload, titles on level transitions.
- Damage/hit flash + tuned screenshake; hitstop safeguards keep time_scale at 1 on reload.

## UI/UX
- Refine menu styling (background art, focus states, controller prompts); add quit/settings entries if desired.
- Improve NoiseCounter placement/styling; consider showing progress only when NoiseBlocks exist.
- HP/feedback UI polish: gradient fill, tick labels, heart art improvements.

## Levels
- Populate Levels 03–04 with enemies/hazards (currently only platforms + NoiseBlocks); place RespawnPoint markers appropriately.
- Balance gaps/pits and platform timings; ensure exits reachable without softlocks.
- Add lore tablets to Levels 03–04 to continue narrative beats; update title/subtitle text if needed.
- Add checkpoints/respawn markers mid-level (optional).

## Enemies & Combat
- Add SFX/telegraph for StaticSpitter and ChasingHazard hits/deaths.
- Projectile pooling + tunable damage/speed for StaticSpitter projectiles.
- Added ChasingHazard and StaticSpitter placements in Levels 03–04; expand with more variants/melee later.

## Systems
- Load game entry hidden until save system exists.
- Add platform fall/respawn VFX/SFX for FallingPlatform; polish MovingPlatform motion easing.
- Confirm NoiseBlock registration/deregistration on reload and destruction in all levels.

## Testing
- Full playthrough: Level_01 → Level_02 → Level_03 → Level_04 with noise gating and kill zones.
- Verify fall death, attack kills enemies (random hit thresholds), exit gating, menu → new game launch flow.
- Check for resource UID issues after adding new scenes (spitters, levels).
