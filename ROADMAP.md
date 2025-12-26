

---

## EPIC 0 — Setup & Base Project

* [X] Crea cartelle progetto standard (`scenes/levels`, `scenes/enemies`, `scripts/...`, `ui`, `assets/audio`, `assets/vfx`)
* [X] Imposta Input Map: `move_left`, `move_right`, `jump`, `dash`, `attack`, `interact`
* [X] Aggiungi scena `Main.tscn` che carica `Level_01` (entrypoint stabile)
* [X] Aggiungi `GameManager` autoload (scene flow + flags debug)

---

## EPIC 1 — Player Game Feel

* [X] Rifinitura dash: distanza percepita, cooldown, lockout (no jump durante dash)
* [X] Aggiungi “facing” (flip sprite / direzione) + posizione AttackHitbox che segue facing
* [X] Aggiungi hitstop micro (0.04–0.06s) su colpo riuscito
* [X] Aggiungi i-frames (invulnerabilità breve) dopo danno (0.5s)
* [X] Aggiungi HP Player (es. 3) + morte (respawn)
* [X] Aggiungi knockback semplice quando prendi danno
* [ ] Aggiungi animazioni placeholder Player (idle/run/jump/dash/attack/hurt)

---

## EPIC 2 — Rhythm & Feedback System

* [ ] Crea `RhythmManager` (timer beat, eventi on-beat, opzionale metronomo)
* [ ] Visual “On Beat” indicator (piccola icona che pulsa quando sei in window)
* [ ] Bilancia: `beat_interval`, `rhythm_window`, decay feedback, gain feedback
* [ ] Regola definitiva: “on-beat = carica feedback” (e basta, niente doppie regole)
* [ ] Aggiungi SFX: click beat + hit_on_beat + miss (3 suoni)

---

## EPIC 3 — NoiseBlock & Interazioni “rumore”

* [ ] NoiseBlock: pulizia finale script (debug flag già ok)
* [ ] NoiseBlock: VFX polish (flash + break particles + shake leggero)
* [ ] Crea variante `NoiseBlockCombo` (richiede N hit on-beat consecutive) **oppure** `NoiseBlockThreshold` (richiede feedback >= soglia)
* [ ] Crea “NoiseDoor” (porta che si apre quando rompi un NoiseBlock specifico)
* [ ] Test: nessun warning AnimationMixer, nessun lock signals

---

## EPIC 4 — HUD & UI

* [ ] Feedback Bar visibile e chiara (animazione smooth + flash quando aumenta)
* [X] HP UI (3 cuori o barra minima)
* [X] Prompt interazione (“E” / “Interagisci”) per lore tablets
* [X] Transizione scene (fade in/out 0.3s) + “Level Title” breve

---

## EPIC 5 — Lore System (Scritte in-game)

* [ ] Crea `LoreTablet.tscn` (Area2D + label UI) con testo export
* [ ] Crea `LoreUI` (CanvasLayer) che mostra testo con typewriter leggero
* [ ] Blocca input durante lettura (solo per 1–2 secondi) o “hold to skip”
* [ ] Scrivi 10 frasi lore (voce Dario) e assegnale ai tablet
* [ ] Test leggibilità: max 1 frase/30–60s, niente muri di testo

---

## EPIC 6 — Enemies (3 tipologie)

### Enemy 1: Drone Patrol

* [ ] `Drone.tscn`: patrol left/right con raycast o bounds
* [ ] HP + hurt + death
* [ ] Danno a contatto
* [ ] Drop “feedback orb” (opzionale)

### Enemy 2: Static Spitter (ranged)

* [ ] `Spitter.tscn`: spara projectile ogni X secondi
* [ ] Projectile: collisione + danno + despawn
* [ ] Telegraph semplice (flash prima di sparare)

### Enemy 3: Bulwark (mini-boss gatekeeper)

* [ ] `Bulwark.tscn`: movimento lento + attacco “slam” a tempo
* [ ] Vulnerabilità: solo on-beat oppure solo con feedback sopra soglia
* [ ] Arena micro + gate finale del slice

---

## EPIC 7 — Level Design (5 minuti vertical slice)

### Level_01 (tutorial invisibile)

* [ ] Layout definitivo + props base + lighting/palette
* [ ] Gate NoiseBlock + Exit funzionante
* [ ] 1 Lore tablet (intro)

### Level_02 (meccanica nuova)

* [ ] Introduci piattaforme “feedback-gated” **oppure** combo gate
* [ ] Inserisci Drone Patrol come primo nemico
* [ ] 2 Lore tablets (mid)

### Level_03 (climax)

* [ ] Arena mini con Spitter + Bulwark
* [ ] Gate finale e uscita
* [ ] Lore finale + title “To be continued”

---

## EPIC 8 — Audio, VFX, Polish

* [ ] Metronomo ambientale (non invadente)
* [ ] Footsteps, dash, jump, hit, hurt, break
* [ ] Particelle: hit spark, break dust, projectile trail
* [ ] Camera: follow + clamp + screen shake leggero su break/hit
* [ ] Bilanciamento finale (tempo totale 4:30–6:00)

---

## EPIC 9 — Build & QA

* [ ] Checklist bug: collisioni, layer/mask, softlock, respawn
* [ ] Playtest interno (tu) con timer: completamento < 6 min
* [ ] Export build (Windows) + versione zip
* [ ] “Release notes” mini + TODO per dopo

---

### Trello “template” consigliato

Liste:

* **Backlog**
* **Next (questa settimana)**
* **Doing**
* **Blocked**
* **Done**

Etichette:

* Gameplay
* UI
* Level
* Enemy
* Lore
* Audio/VFX
* Bug

---
