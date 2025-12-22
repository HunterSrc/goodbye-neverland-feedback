# GoodbyeNeverland — Vertical Slice (Godot 4.5.1) — Continuation Prompt for Cursor/GPT (v2)

## Project goal
Build a **5-minute super-polished vertical slice** (2D platform/action) inspired by Hollow Knight/Silksong, with **rhythm-driven combat** and **short interactable lore**.

The slice must feel like a “real game”:
- tight movement (fast dash, responsive jump)
- clear feedback (hitstop, screenshake, UI)
- small but strong atmosphere (palette/props/FX)
- readable story beats (lore tablets)

---

## Narrative context (Dario + Noise)
**Dario** is kicked out of his band. He sinks into depression, then regains the desire to play again.  
The obstacle is internal: **the “Noise” in his head** prevents him from writing new songs.

He starts an adventure across **6 distinct stages (Levels)**, each with a specific peculiarity/mechanical twist.  
The final stage has a boss: **his dark version**, the union of all noises.

Vertical slice scope (5 min):
- We foreshadow the 6-stage arc with lore + motifs, but implement only the first 2–3 micro-levels for now.

Lore delivery:
- **Interact-based** (player presses an action key to read).
- Text style: short lines, evocative, “song lyric / diary fragments”, no walls of text.

---

## Engine / stack
- **Godot 4.5.1**
- Scene flow: `Main.tscn` loader with fade + title/subtitle cards
- **GameManager autoload** for global utilities (hitstop, screenshake, load_level wrapper, flags)

---

## Current state (implemented)
### Scene flow
- `Main.tscn` is the main run scene.
- `Main.gd`:
  - loads first level via `@export var first_level: PackedScene`
  - has `load_level(scene)` with:
    - fade in/out
    - title + subtitle card with whoosh SFX
    - input lock during transitions
  - owns **Camera2D** (active Current=true), follows player and supports **screenshake**

### GameManager autoload
- `GameManager.gd` (autoload):
  - debug flags
  - `hitstop()` using `Engine.time_scale` (timer ignores time scale)
  - `screenshake()` forwarding to Main.shake()
  - `load_level(scene)` wrapper that prefers calling Main.load_level()

### Core gameplay
#### Player
- `Player.gd` (CharacterBody2D):
  - movement + jump
  - **fast dash**: dash_speed ~900, dash_duration ~0.10, cooldown ~0.30
  - dash works in air, **gravity applies during dash**
  - **1 air dash per jump** (resets on floor)
  - attack via `AttackHitbox` Area2D; `CollisionShape2D` enabled only during attack window
  - rhythm system:
    - `beat_interval` + `rhythm_window`
    - on-beat attack increases feedback
  - feedback meter:
    - increases on-beat
    - decays over time
    - spendable via `consume_feedback(amount)`
  - facing system:
    - player sprite node name is **Sprite** (confirm type: Sprite2D)
    - facing flips sprite + moves attack hitbox offset (`hitbox_offset_x`)
    - **facing lock during attack** + extra delay (`facing_lock_extra`)
  - i-frames system is integrated:
    - `take_damage(amount, from_pos)` applies invuln timer + knockback + blink
  - HP + death/respawn currently exists, but must be finalized for the chosen behavior:
    - **On death: reload the current level** (NOT just reposition).

#### NoiseBlock
- `NoiseBlock.gd`:
  - StaticBody2D obstacle with `HitArea` Area2D
  - requires confirmed combat hit:
    - checks `is_attack_active()` and `is_on_beat_attack()` on the attacking Area2D
  - consumes player feedback to break (`feedback_required`)
  - animations: `hit_on_beat`, `break`
  - uses `set_deferred` when disabling monitoring/collision during signals
  - triggers `GameManager.hitstop()` + `GameManager.screenshake()` when hit is confirmed on-beat

### Levels
- Level_01 and Level_02 exist, can transition via Exit + Main loader.
- Player is found reliably through group `"player"` (avoid current_scene paths).
- Static bodies need visuals (Polygon2D) or debug collision overlay.

---

## Design pillars (for this slice)
1) **Rhythm = power**: on-beat actions build “clarity/energy” (feedback), enabling progress through Noise.
2) **Noise as obstacle/enemy**: environmental blocks + enemies represent intrusive thoughts.
3) **Lore in fragments**: interact-based tablets, short lines, recurring motifs (stage names, chorus/verse metaphors).

---

## Collision philosophy (must remain stable)
- Separate physical collision from combat detection:
  - Player body collides with world
  - AttackHitbox only detects enemy/hit areas
  - HitAreas must not trigger by proximity (only when attack is active)

Use groups and node references robustly:
- Player is in group `"player"`
- Respawn markers use group `"respawn"` (optional for later)
- Avoid `get_tree().get_current_scene().get_node("Player")` (Main is current scene now)

---

## What is next (priorities)
### Priority 1 — finalize HP + death behavior
We decided:
- HP = **3 hearts** UI
- On death: **RELOAD CURRENT LEVEL** (full reset of blocks/enemies/state)

So we need:
1) A reliable way to know the currently loaded PackedScene path/identifier.
2) Player death should request reload via `GameManager.load_level(...)` (or Main.load_level)
3) Ensure time_scale resets and input is restored correctly after reload.

### Priority 2 — Lore system (Interact)
- Create `LoreTablet.tscn` (Area2D + prompt)
- Create `LoreUI` (CanvasLayer) with text display (typewriter optional)
- Interaction key: `interact`
- While reading: either lock movement for a short moment or allow movement but hide after input (decide later).

### Priority 3 — UI
- HP hearts UI (3 hearts) + damage feedback
- Feedback bar (smooth) + on-beat indicator

### Priority 4 — Enemies
- Enemy 1: Drone Patrol (patrol + contact damage calling `player.take_damage(1, global_pos)`)
- Use hitstop/shake on successful hits.

---

## Task request to Cursor/GPT (what to do now)
You are the senior Godot engineer + gameplay designer. Please:

### A) Finalize level reload on death (Godot 4.5.1)
1) Update `GameManager` and/or `Main` to support **reload current level**:
   - store `current_level_scene_path` / reference to PackedScene
   - implement `GameManager.reload_level()` or `Main.reload_current_level()`
2) Update `Player._die()` to call reload, not respawn-position.
3) Ensure:
   - Engine.time_scale returns to 1.0 even if death occurs during hitstop
   - transitions still work (fade, title card optional on reload)
   - no stuck input lock after reload

### B) Implement HP hearts UI (simple but polished)
1) Create `UIRoot.tscn` (CanvasLayer) or integrate into Main:
   - 3 heart icons (TextureRect) or drawn shapes
2) UI reads player HP:
   - either via group `"player"` or a small signal-based approach
3) Add micro polish:
   - heart pop/shake on damage
   - flash red briefly on screen edges (optional later)

### C) Create a debug Hazard to test damage
- `Hazard.tscn` (Area2D) that calls `player.take_damage(1, global_position)` on body_entered
- Used to validate i-frames + death reload loop

Constraints:
- Keep changes incremental, stable, and easy to wire in editor.
- Use groups or `get_node_or_null` to avoid brittle paths.
- Output full file contents or clear patch blocks.
- Provide editor wiring checklist + minimal test plan per feature.

---

## Known node requirements
Main scene expected nodes:
- `TransitionLayer/FadeRect` (ColorRect)
- `TransitionLayer/TitleLabel` (Label)
- `TransitionLayer/SubtitleLabel` (Label)
- `TransitionLayer/SfxPlayer` (AudioStreamPlayer)
- `Camera2D` (Camera2D, Current=true)

Player scene expected nodes:
- `Sprite` node exists (likely Sprite2D)
- `AttackHitbox/CollisionShape2D` exists

Groups:
- Player is in `"player"`

---

## Decisions already made (do not ask again)
- Godot version: **4.5.1**
- Player sprite node name: **Sprite**
- Death behavior: **reload the level**
- Lore: **interact-based**
- HP UI: **hearts**

---

## Remaining questions (only if needed)
1) Should a level reload show title/subtitle again, or do a faster fade-only reload?
2) On lore interact: do we freeze player while reading, or allow movement?

---

## Output format requested
When you propose edits, output:
- Full file contents (or patch blocks) for:
  - `GameManager.gd`
  - `Main.gd` (only if needed)
  - `Player.gd` (death reload integration)
  - UI scripts/scenes as text instructions
  - `Hazard.gd` (new)
- A short editor wiring checklist.
- A minimal test plan:
  - take damage, verify i-frames blink
  - die, verify full level reload
  - verify time_scale resets
  - verify UI hearts match HP
