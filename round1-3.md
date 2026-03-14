# GAME DESIGN DOCUMENT
### Hackathon Theme: *"Death is not the end"*
### Inspired by: Buckshot Roulette | Engine: Godot (2D Top-Down)

---

## OVERVIEW

A turn-based 2-player game (YOU vs DEALER) set around a table where players take turns firing a shotgun at each other or themselves. The game revolves around live and blank shells, health charges, and items that alter the flow of play. The tension escalates across 4 rounds — Round 4 only unlocks if you die in Round 3. If you die in Round 4, you restart the entire game from Round 1.

**Shell Types:**
- **Live Shell** — Red. Deals damage when fired.
- **Blank Shell** — Greyish-blue. Does nothing when fired.

**Maximum barrel capacity:** 8 shells (any mix of live and blank).

---

## PLAYERS

| Player | Description |
|--------|-------------|
| **YOU (Human)** | The human player. Rounds 1–3. First-person perspective facing the Dealer. |
| **DEALER** | The AI opponent sitting across the table in all 4 rounds. |

---

## STRUCTURE: 4 ROUNDS (3 + 1)

```
Round 1 ──► Round 2 ──► Round 3 ──► WIN → Declared Winner
   ▲                         │
   │                    Die here?
   │                         │
   │                         ▼
   │                      Round 4
   │                   "The Other Side"
   │                         │
   │                    Win Round 4?
   │                         │
   │              ┌──────────┘
   │              │
   │         Return to Round 3
   │         (full reset — player & dealer
   │          health + items reset to Round 3 defaults)
   │
   └── Die in Round 4 → Restart from Round 1
```

**Death & progression consequences:**
- Die in **Round 1** → restart from Round 1.
- Die in **Round 2** → restart from Round 1.
- Die in **Round 3** → enter Round 4.
- **Win Round 3** → **immediately declared the winner. Game ends. Round 4 is never entered.**
- **Win Round 4** → return to Round 3 with full reset: both player and dealer health and items are reset to their Round 3 starting values.
- Die in **Round 4** → restart from Round 1.

> ⚠️ **IMPORTANT:** Round 4 is **exclusively a death state** — it is only ever entered by dying in Round 3. A player who wins Round 3 never sees Round 4.

---

## HEALTH / CHARGES SYSTEM

Health is represented as **charges** — not a traditional HP bar. Each charge represents one hit the player can absorb.

| Round | Regular Charges | Faded Charges |
|-------|----------------|---------------|
| Round 1 | 2 | 0 |
| Round 2 | 4 | 0 |
| Round 3 | 4 | 2 |
| Round 4 | TBD | — |

### Faded Charges (Round 3 only)
- Faded charges appear visually cracked, dim, and broken — distinct from clean regular charges.
- They represent a damaged defibrillator: high-stakes, end-of-the-line energy.
- Both YOU and the DEALER start Round 3 with **4 regular + 2 faded charges**.

### The Cable-Cutting Mechanic (Round 3 only)
- When a player loses all their **regular (non-faded) charges**, an animation plays showing the cables above that player's side of the machine being cut.
- **After the cables are cut:**
  - That player **can no longer heal**.
  - Any subsequent damage received is **instantly fatal**.
- If YOU are killed in Round 3 this way → you enter **Round 4**.

---

## BARREL / SHELL CONFIGURATION

| Round | Total Shells | Configuration |
|-------|-------------|---------------|
| Round 1 | Randomized (min: 3) | Configurable |
| Round 2 | Randomized (min: 3) | Configurable |
| Round 3 | Randomized (min: 3) | Configurable |
| Round 4 | TBD | Configurable |

- **Rounds 1–3:** Shell count is randomized each run, with a configurable minimum (must be greater than 2). The live/blank split within that count is also randomized.
- All shell counts must be **configurable via a settings/config file** to allow easy playtesting and balancing without changing code.
- **Shell reveal:** At the beginning of every round, the full barrel composition is shown to both players for **3 seconds** before play begins.

---

## ITEMS

Players receive items at the **start of each round**. Items are used on your turn.

> **Multiple items per turn:** A player can use **more than one item in a single turn** before firing. There is no limit to how many items can be chained together in one turn — a player may use all of their remaining items before finally taking their shot.

| Round | Items per Player |
|-------|----------------|
| Round 1 | **0** — No items. Pure mechanics. |
| Round 2 | **2 items** |
| Round 3 | **4 items** |
| Round 4 | TBD |

---

### 1. Magnifying Glass
Reveals whether the **current shell** in the barrel is live or blank before you act.

---

### 2. Cigarette
Increases your charge/health by **one**.

---

### 3. Beer Can
Ejects the current shell from the barrel. You **cannot** look at it before ejection — discarded blind.

---

### 4. Handcuffs
Skips the opponent's next turn entirely. The barrel advances normally (the skipped shell is consumed/lost).

---

### 5. Handsaw
Doubles the damage dealt by the shotgun for the next shot fired.

---

## ROUND-BY-ROUND BREAKDOWN

---

### ROUND 1
- **Your charges:** 2
- **Dealer charges:** 2
- **Items per player:** 0
- **Barrel:** Randomized, min 3 shells, configurable
- **Special mechanics:** None
- **Tone:** Clean introduction to the core loop. No items — pure reads, pure probability.
- **Death consequence:** Restart from Round 1.

#### Dealer AI Behaviour — Round 1
The Dealer plays straightforwardly. No items to consider. Core logic:
- If the Dealer knows the current shell is live → shoot the player.
- If the Dealer knows the current shell is blank → shoot themselves (self-blanks preserve your turn).
- If unknown → calculate probability based on remaining live/blank count. Shoot player if live probability is high; shoot self if blank probability is high.

---

### ROUND 2
- **Your charges:** 4
- **Dealer charges:** 4
- **Items per player:** 2
- **Barrel:** Randomized, min 3 shells, configurable
- **Special mechanics:** Items introduced
- **Tone:** Escalation. Longer exchanges. Items create new decision layers.
- **Death consequence:** Restart from Round 1.

#### Dealer AI Behaviour — Round 2
The Dealer now has items and uses them tactically:
- **Magnifying glass** → always used when shell is unknown and the decision is high-stakes.
- **Cigarette** → used when at low health (1 charge remaining).
- **Beer Can** → used when the Dealer suspects the current shell is live but wants to deny it, or to avoid wasting a turn on a blank.
- **Handcuffs** → used when the Dealer has a confirmed live shell and wants to shoot twice uninterrupted, or when the player is at 1 charge.
- **Handsaw** → used when the Dealer has a confirmed live shell and the player has more than 1 charge.

General priority: the Dealer prefers eliminating the player over self-preservation when health allows. As the Dealer's health drops to 1 charge, it shifts to a more defensive/healing-first approach.

---

### ROUND 3 — *"Sudden Death"*
- **Your charges:** 4 regular + 2 faded
- **Dealer charges:** 4 regular + 2 faded
- **Items per player:** 4
- **Barrel:** Randomized, min 3 shells, configurable
- **Special mechanics:** Faded charges, Cable-Cutting mechanic
- **Tone:** End-of-the-line. The defibrillator is damaged. One mistake too many and the cables get cut.
- **Win condition:** Deplete the Dealer's health → **immediately declared winner.**
- **Death consequence:** Enter Round 4.

#### Dealer AI Behaviour — Round 3
Same as Round 2 AI but with additional awareness of the faded charge system:
- The Dealer tracks whether its own cables are cut → shifts to full aggression, no point saving items for healing.
- The Dealer tracks whether YOUR cables are cut → if yes, any live shell is a kill shot; becomes extremely aggressive, prioritising confirmed live shells and handsaw usage.
- If both cables are cut, the round becomes a pure information/positioning game — magnifying glass and beer can used aggressively to find and fire confirmed live shells.
- The Dealer does not intentionally waste faded charges — still tries to preserve them.

---

### ROUND 4 — *"The Other Side"* *(details TBD)*

> Round 4 is a special hidden round accessed only by dying in Round 3. Full mechanics are being designed separately and will be documented here once finalised.

**What is confirmed:**
- Entered only by dying in Round 3.
- If you **win Round 4** → you are returned to Round 3 from the beginning. Both your health and the Dealer's health are fully reset to Round 3 starting values (4 regular + 2 faded charges each). All items for both players are also reset to Round 3 starting counts.
- If you **lose Round 4** → restart the entire game from Round 1.
- The player's **goal and mechanics are fundamentally different** from Rounds 1–3 — details TBD.

---

## ITEMS SUMMARY TABLE

| Item | Round 1 | Round 2 | Round 3 | Round 4 |
|------|---------|---------|---------|---------|
| Magnifying Glass | — | ✓ | ✓ | TBD |
| Cigarette | — | ✓ | ✓ | TBD |
| Beer Can | — | ✓ | ✓ | TBD |
| Handcuffs | — | ✓ | ✓ | TBD |
| Handsaw | — | ✓ | ✓ | TBD |

---

## DEATH & PROGRESSION FLOWCHART

| Situation | Consequence |
|-----------|-------------|
| Die in Round 1 | Restart from Round 1 |
| Die in Round 2 | Restart from Round 1 |
| Win Round 3 | **Victory — game ends** |
| Die in Round 3 | Enter Round 4 |
| Win Round 4 | Return to Round 3 — full health + items reset for both players |
| Die in Round 4 | Restart from Round 1 |

---

## CONFIG / BALANCING REFERENCE

All of the following should be exposed as configurable values:

```
round_1_min_shells        = 3
round_1_max_shells        = 6       # suggested starting range
round_2_min_shells        = 3
round_2_max_shells        = 7
round_3_min_shells        = 4
round_3_max_shells        = 8
round_4_shells            = TBD

round_2_items_per_player  = 2
round_3_items_per_player  = 4
round_4_items_per_player  = TBD

shell_reveal_seconds      = 3       # duration barrel composition is shown at round start
sabotage_window_seconds   = 3       # ghost ally sabotage window (Round 3 post-resurrection)
```

---

*Document version: v0.3 — Round 4 details deferred pending implementation*
*Last updated: March 2026*