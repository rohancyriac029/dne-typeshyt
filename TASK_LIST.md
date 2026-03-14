# Buckshot Roulette – MVP Task List

## Phase 0 – Asset Collection ✅ Complete

> Vignette is **NOT an image asset** — implemented as a Godot shader (see Phase 1).

| Asset File | Folder | Status |
|---|---|---|
| `table_background.png` | `Assets/Environment/` | ✅ Added |
| `dealer_sprite.png` | `Assets/Characters/` | ✅ Added |
| `player_hands.png` | `Assets/Characters/` | ✅ Added |
| `shotgun_sprite.png` | `Assets/Objects/` | ✅ Added |
| `live_shell_icon.png` | `Assets/Objects/` | ✅ Added |
| `blank_shell_icon.png` | `Assets/Objects/` | ✅ Added |
| `hp_icon.png` | `Assets/UI/` | ✅ Added |
| `shoot_self_button.png` | `Assets/UI/` | ✅ Added |
| `shoot_dealer_button.png` | `Assets/UI/` | ✅ Added |
| `shell_counter_ui.png` | `Assets/UI/` | ✅ Added |
| `muzzle_flash.png` | `Assets/Effects/` | ✅ Added |
| `blank_click_icon.png` | `Assets/Effects/` | ✅ Added |

---

## Phase 1 – Project Setup ✅ Complete
- [x] Create `project.godot` (1152×648, Forward Plus, GameStateManager autoload)
- [x] Add `GameStateManager` Autoload singleton
- [x] Create `MainScene.tscn` with root Node2D + `MainScene.gd`
- [x] Add `Player` and `Dealer` nodes to scene (HealthComponent.gd)
- [x] **Shader Vignette** — `CanvasLayer → VignetteOverlay (ColorRect)` + `vignette.gdshader`
  - Center at UV (0.5, 0.35); params: strength=0.3, radius=0.75, softness=0.45

---

## Phase 2 – Turn System ✅ Complete
- [x] FSM states: `INIT → ROUND_START → LOAD_SHELLS → PLAYER_TURN / DEALER_TURN → RESOLVE_SHOT → WIN / LOSE`
- [x] `ShootSelfButton` → `PlayerController.on_shoot_self_pressed()`
- [x] `ShootDealerButton` → `PlayerController.on_shoot_dealer_pressed()`
- [x] Turns alternate after each shot (in `GameStateManager._check_reload_then_switch_turn()`)

---

## Phase 3 – Shell System ✅ Complete
- [x] `ShotgunSystem.load_shells(live, blank)` — fills array
- [x] Shuffle via `shells.shuffle()`
- [x] `ShotgunSystem.fire()` — pops front
- [x] `ShotgunSystem.peek_next()` helper

---

## Phase 4 – Shot Resolution ✅ Complete
- [x] LIVE → `target.take_damage(1)`
- [x] BLANK → shooter gets extra turn (no switch)
- [x] `RESOLVE_SHOT` state in `GameStateManager._resolve_shot()`

---

## Phase 5 – HP System ✅ Complete
- [x] `HealthComponent.gd` on Player and Dealer (`max_hp`, `current_hp`, signals)
- [x] `hp_changed` → UIManager updates labels
- [x] `entity_died` signal present

---

## Phase 6 – Round System ✅ Complete
- [x] 3 round configs in `RoundSystem._get_config()`
- [x] `load_round()`, `reload_shells()`, `end_round()`
- [x] Dealer random AI in `DealerTurnLogic.take_turn()`

---

## Phase 7 – End Conditions ✅ Complete
- [x] Player HP=0 → `LOSE` state → `LoseScreen.tscn`
- [x] Dealer HP=0 → `WIN` state → `WinScreen.tscn`
- [x] Restart / Quit buttons on both screens (signals wired in .tscn)

---

## ⚠️ Open — Wire in Godot Editor
- [ ] Open project in Godot 4 and verify scene loads without errors
- [ ] Adjust sprite scales for `TableSprite`, `DealerSprite`, `ShotgunSprite`, `PlayerHandsSprite` to fit screen
- [ ] Verify vignette effect is visible

---

## Definition of Done ✅
- [ ] Player can shoot self or dealer
- [ ] Shells randomize each round
- [ ] Blank gives extra turn
- [ ] Live deals damage
- [ ] Dealer acts randomly
- [ ] HP hits zero correctly
- [ ] Game ends after 3 rounds or on HP=0
- [ ] Win / Lose screen appears
