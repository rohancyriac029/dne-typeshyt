
# Buckshot Roulette – First Playable Version (MVP) Roadmap
Grounded strictly on the provided Technical Design Document.

---

# 1. Scope of First Playable Version

The MVP demonstrates the **core gameplay loop** only. According to the document, the MVP must prove that:

- The shell system works
- Turn order works
- Damage / HP system works
- Win / loss detection works
- Three rounds escalate difficulty

The document explicitly states that **art, animations, audio, and items are NOT required for MVP**.

Therefore assets are limited to **minimal functional UI and scene placeholders**.

---

# 2. Core Gameplay Loop (From Design Doc)

Player and Dealer alternate turns using a shotgun containing live and blank shells.

Possible actions:

- Shoot self
- Shoot dealer

Rules:

- If shell = LIVE → target loses HP
- If shell = BLANK → shooter gets another turn
- Game ends when:
  - Player HP = 0 → Lose
  - Dealer HP = 0 → Win

The loop repeats across **3 rounds with increasing shell counts and HP**.

---

# 3. Core Systems Required

## 3.1 Game State Machine

States defined in the design doc:

```
INIT
ROUND_START
LOAD_SHELLS
DEAL_ITEMS
PLAYER_TURN
DEALER_TURN
RESOLVE_SHOT
WIN
LOSE
```

Transitions are managed by `GameStateManager`.

Responsibilities:

- Control turn order
- Start new rounds
- Detect win/loss
- Broadcast state changes

---

## 3.2 Round System

Controls:

- Round number
- Shell counts
- Player HP
- Dealer HP

Round escalation example:

| Round | Live | Blank | HP |
|------|------|------|------|
| 1 | 2 | 2 | 2 |
| 2 | 2–4 | 2–4 | 4 |
| 3 | 3–6 | 2–6 | 6 |

Functions:

```
load_round()
deal_items()
end_round()
```

---

## 3.3 Shotgun System

Responsible for managing shells.

Data structure:

```
Array<ShellType>
```

Shell types:

```
LIVE
BLANK
```

Key operations:

```
load_shells(live, blank)
fire()
peek_next()
```

Algorithm:

1. Fill array with live + blank shells
2. Shuffle array
3. Pop first element when firing

---

## 3.4 Damage & Health System

Attached to both Player and Dealer.

Data:

```
max_hp
current_hp
```

Signals:

```
hp_changed
entity_died
```

Damage logic:

```
if shell == LIVE:
    target.hp -= damage
```

---

## 3.5 Player Input System

Handles UI interactions.

Actions:

```
SHOOT_SELF
SHOOT_DEALER
```

Emits signal:

```
player_action(action)
```

---

## 3.6 Dealer Turn Logic (MVP)

For MVP the dealer **does not require AI**.

Implementation allowed by document:

```
choose randomly:
    shoot self
    shoot player
```

---

# 4. Algorithms Used

## Shell Randomization

```
shells = []
add LIVE shells
add BLANK shells
shuffle(shells)
```

## Shot Resolution

```
shell = shotgun.fire()

if shell == LIVE:
    target.take_damage()
else:
    shooter gets extra turn
```

## Turn Switching

```
if player_turn:
    dealer_turn
else:
    player_turn
```

## Win/Loss Detection

```
if player_hp == 0 → LOSE
if dealer_hp == 0 → WIN
```

---

# 5. Scene Architecture (2D MVP)

```
MainScene
    Table
    Shotgun
    Player
    Dealer
    UI
        PlayerHP
        DealerHP
        ShellCounter
        ShootSelfButton
        ShootDealerButton
```

---

# 6. Asset Requirements (MVP)

Although the document says MVP can run without art, a **minimal playable 2D version** requires the following.

## Environment

| Asset | Purpose |
|------|------|
| `table_background.png` | main play surface |

> **Vignette effect** is implemented as a Godot 4 CanvasItem shader — NOT a PNG file.
> `CanvasLayer → ColorRect (VignetteOverlay)` with `vignette_strength=0.3`, `vignette_radius=0.75`, `softness=0.45`

## Characters

| Asset | Purpose |
|------|------|
dealer_sprite.png | dealer presence |
player_hands.png | player representation |

These can be **cropped from the provided image**.

## Gameplay Objects

| Asset | Purpose |
|------|------|
shotgun_sprite.png | central weapon |
live_shell_icon.png | live shell indicator |
blank_shell_icon.png | blank shell indicator |

## UI

| Asset | Purpose |
|------|------|
hp_icon.png | health indicator |
shoot_self_button.png | player action |
shoot_dealer_button.png | player action |
shell_counter_ui.png | display shell counts |

## Optional Visual Feedback

| Asset | Purpose |
|------|------|
muzzle_flash.png | firing effect |
blank_click_icon.png | blank shot feedback |

---

# 7. Folder Structure

```
Assets
    Characters
        dealer_sprite.png
        player_hands.png

    Objects
        shotgun_sprite.png
        live_shell_icon.png
        blank_shell_icon.png

    Environment
        table_background.png
        (no vignette PNG — shader only)

    UI
        hp_icon.png
        shoot_self_button.png
        shoot_dealer_button.png
        shell_counter_ui.png

    Effects
        muzzle_flash.png
        blank_click_icon.png
```

---

# 8. Development Roadmap

## Phase 1 – Project Setup

Tasks:

- Create Godot project
- Add `GameStateManager` Autoload singleton
- Create main scene
- Add `Player` and `Dealer` nodes
- **Shader Vignette**: Add `CanvasLayer → ColorRect (VignetteOverlay)` with full-screen anchors and a `ShaderMaterial` using `vignette.gdshader`
  - Center at UV (0.5, 0.35) — spotlight-over-table effect
  - Params: `vignette_strength=0.3`, `vignette_radius=0.75`, `softness=0.45`

Goal:

Scene loads with subtle vignette visible.

---

## Phase 2 – Turn System

Tasks:

- Implement FSM transitions
- Add player input buttons
- Switch turns after action

Goal:

Turns alternate correctly.

---

## Phase 3 – Shell System

Tasks:

- Implement shell loading
- Implement shuffle algorithm
- Implement fire()

Goal:

Shotgun returns correct shell type.

---

## Phase 4 – Shot Resolution

Tasks:

- Apply damage for live shells
- Allow extra turn for blanks

Goal:

Correct gameplay behaviour.

---

## Phase 5 – HP System

Tasks:

- Add HealthComponent to Player and Dealer
- Display HP in UI

Goal:

Damage and death detection work.

---

## Phase 6 – Round System

Tasks:

- Implement 3 round configurations
- Reload shells when empty

Goal:

Game progresses through rounds.

---

## Phase 7 – End Conditions

Tasks:

- Detect player death
- Detect dealer death
- Show win/lose screen

Goal:

Game ends correctly.

---

# 9. Definition of Done

The first playable version is complete when:

- Player can shoot self or dealer
- Shells randomize correctly
- Blank gives extra turn
- Live deals damage
- Dealer performs random action
- HP reaches zero correctly
- Game ends after 3 rounds

