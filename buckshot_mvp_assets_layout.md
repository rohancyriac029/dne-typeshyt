
# Buckshot Roulette – MVP Assets, Directory Layout, and Positioning

Grounded strictly on the provided technical design document.

---

# 1. MVP Scope

The MVP demonstrates the core loop:

- Player shoots self or dealer
- Shell is live or blank
- Live → damage
- Blank → extra turn
- Dealer takes a random action
- Game progresses through 3 rounds
- HP reaches 0 → win or lose

No items, audio, or advanced UI are required for MVP.

---

# 2. Asset Directory Structure

Recommended project asset structure:

```
Assets/
    Environment/
        table_background.png

    Characters/
        dealer_sprite.png
        player_hands.png

    Objects/
        shotgun_sprite.png
        live_shell_icon.png
        blank_shell_icon.png

    UI/
        hp_icon.png
        shoot_self_button.png
        shoot_dealer_button.png
        shell_counter_ui.png

    Effects/
        muzzle_flash.png (optional)
        blank_click_icon.png (optional)
```

> **Note:** The vignette effect is NOT an image file. It is implemented as a Godot 4 CanvasItem shader (see Section 9).

---

# 3. Scene Layout (Godot 2D)

Main scene layout:

```
MainScene
    TableSprite
    DealerSprite
    ShotgunSprite
    PlayerHandsSprite
    UI
        PlayerHP
        DealerHP
        ShellCounter
        ShootSelfButton
        ShootDealerButton
```

---

# 4. Asset Positioning

The game camera represents a player sitting at a table facing the dealer.

### Table Background

Asset:

```
Assets/Environment/table_background.png
```

Position:

```
center of the screen
covers most of viewport
```

Suggested Godot settings:

```
Position: (screen_width/2 , screen_height/2)
Anchor: center
```

---

### Dealer Sprite

Asset:

```
Assets/Characters/dealer_sprite.png
```

Position:

```
top-center of the screen
slightly overlapping the table
```

Suggested coordinates:

```
Position: (screen_width/2 , 100)
```

The dealer should appear leaning over the table.

---

### Player Hands

Asset:

```
Assets/Characters/player_hands.png
```

Position:

```
bottom-center of the screen
hands resting on table edge
```

Suggested coordinates:

```
Position: (screen_width/2 , screen_height - 120)
```

---

### Shotgun

Asset:

```
Assets/Objects/shotgun_sprite.png
```

Position:

```
center of the table
between player and dealer
```

Suggested coordinates:

```
Position: (screen_width/2 , screen_height/2)
```

---

# 5. UI Layout

### HP Icons

Asset:

```
Assets/UI/hp_icon.png
```

Positions:

Player HP:

```
top-left corner
Position: (40 , 40)
```

Dealer HP:

```
top-right corner
Position: (screen_width - 120 , 40)
```

---

### Shoot Buttons

Assets:

```
Assets/UI/shoot_self_button.png
Assets/UI/shoot_dealer_button.png
```

Position:

Bottom of screen above player hands.

Example:

Shoot Self:

```
Position: (screen_width/2 - 200 , screen_height - 40)
```

Shoot Dealer:

```
Position: (screen_width/2 + 200 , screen_height - 40)
```

---

### Shell Counter

Asset:

```
Assets/UI/shell_counter_ui.png
```

Position:

```
top-center of screen
```
Suggested coordinates:

```
Position: (screen_width/2 , 40)
```

Purpose:

Displays remaining:

- live shells
- blank shells

---

# 6. Minimum Required Assets

Required assets for MVP (all collected ✅):

```
table_background.png
dealer_sprite.png
player_hands.png
shotgun_sprite.png

live_shell_icon.png
blank_shell_icon.png

hp_icon.png
shoot_self_button.png
shoot_dealer_button.png
shell_counter_ui.png
```

Optional (collected ✅):

```
muzzle_flash.png
blank_click_icon.png
```

> **Vignette** → implemented as a shader, not a PNG (see Section 9).

---

# 7. Rendering Order (Important)

Node draw order from back to front:

```
1 table_background
2 dealer_sprite
3 shotgun_sprite
4 player_hands
5 UI
```

This ensures:

- table is background
- dealer appears above table
- player hands appear in foreground

---

# 8. Definition of Done

MVP is complete when:

- player can shoot self
- player can shoot dealer
- shells randomize
- live shells deal damage
- blank shells grant extra turn
- dealer performs random action
- HP reaches zero correctly
- win/lose screen appears

---

# 9. Vignette – Shader Implementation

The dark vignette effect is resolution-independent and requires **no image file**.

## Scene Setup

```
CanvasLayer  (VignetteLayer)
    ColorRect  (VignetteOverlay)
        anchors: full-screen (0,0 → 1,1)
        ShaderMaterial → vignette.gdshader
```

## Shader Behaviour

- Type: `CanvasItem` shader
- Calculates UV distance from a center point
- Applies `smoothstep` radial gradient: edges darken, center stays clear
- Center is offset slightly upward (y ≈ 0.35) to simulate a table spotlight

## Exposed Parameters

| Parameter | Default | Effect |
|---|---|---|
| `vignette_strength` | `0.3` | Max darkening at edges (0 = none, 1 = black) |
| `vignette_radius` | `0.75` | Inner radius before darkening starts |
| `softness` | `0.45` | Gradient spread / feathering |

## Draw Order

The `CanvasLayer` should sit above the game scene but below interactive UI buttons, so gameplay elements remain fully visible.
