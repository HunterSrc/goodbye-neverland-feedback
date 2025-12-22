# Changelog

## 2025-12-22
- Implemented level reload on player death (Main/GameManager wrappers, Player death flow with time_scale reset safety).
- Added HP hearts UI and feedback bar in `scenes/ui/UIRoot.tscn` with damage pop/shake and beat indicator.
- Created Lore system with `LoreTablet` interact + `LoreUI` display (typewriter, close hint, player lock).
- Added Hazard test Area2D for damage loop validation and DronePatrol contact damage enemy.
- Expanded Level_01 and Level_02 layouts with platforms, respawn markers, NoiseBlocks gates, lore tablets, enemies, and exits for progression.
- Improved NoiseBlock robustness after reload (state reset, HitArea re-enable, player refetch).
- Buffed Player jump height by ~10% and maintained dash/rhythm/feedback combat core.
- Hooked HP UI to Player `hp_changed` signal and auto-rebind on level reload; Main now updates GameManager.current_level_path on every load.
- Added screen-edge damage flash in HP UI (DamageFlash overlay with tweened red pulse on HP loss).
- Feedback bar UI now shows numeric charge (`FEEDBACK X / Y`) and tints fill color based on charge level.
- Feedback bar visuals improved with outline/background styling and fixed size for clearer bar representation.
- Added SFX plumbing in GameManager (beat/hit/miss/damage AudioStream players) and Player damage triggers GameManager.play_damage().
- LoreTablet prompt polished: configurable text, fade-in/out tween on enter/exit, stays hidden while reading and after reloads.
- Player damage polish: optional mini screenshake on taking damage (duration/strength tunable).
- Feedback bar now includes tick marks for thresholds.
- Level/title flow configurable: GameManager exports for fade/title on level load vs reload; Main respects show_title flag.
- Added StaticSpitter enemy (fires SpitProjectiles) and placed one in Level_02.
- Added feedback-gated platform (consumes feedback to become solid briefly) and placed one in Level_02; Spitter now has muzzle flash telegraph.
- Added 8 enemy variants (multi-direction Spitter scenes + ChasingHazard patrol/chase) and rebalanced Level_02 enemy placement; FeedbackPlatform shows cost label with activation flash.
- Added fall-death kill zones to Level_01 and Level_02 with player `kill()` support; expanded both levels with longer layouts and pits requiring jumps, repositioned exit, floors, and platforms.
- Enemies now destructible: DronePatrol, all StaticSpitter variants, and ChasingHazard have random hit thresholds, detect player attacks via HitAreas (layer 16/mask 5), and die after sufficient hits.
- Noise gating: GameManager tracks NoiseBlocks (total/destroyed), NoiseBlocks register/deregister on break; Exit requires all NoiseBlocks cleared. Added HUD NoiseCounter showing destroyed/total.
- Added Level_03 (vertical climb with falling/moving platforms, NoiseBlocks, kill zone, exit to Level_04) and Level_04 (moving platforms, NoiseBlocks, kill zone); Level_02 now chains to Level_03. Updated title/subtitle cards for Levels 3–4 to push the lore.
- Added main menu scene (`scenes/Menu.tscn`) with selectable “Nuova avventura” (starts Main) and “Carica” (prints placeholder); supports mouse/keyboard/tap.
