# ROUND 4 & POST-RESURRECTION ROUND 3
### Supplement to Main Game Design Document

---

## ROUND 4 — "The Other Side"

### Overview
Round 4 is a hidden round accessible **only by dying in Round 3**. The player is now a Ghost — still sitting across the same table, facing the same Dealer. The shotgun is still there. But the rules of the living no longer apply.

The goal is not to kill the Dealer. The goal is to **shoot yourself with a live shell** before the Dealer does. You are racing for the same bullet.

---

### Players & Identity

| Entity | Description |
|--------|-------------|
| **YOU (Ghost)** | You died in Round 3. You are now a ghost. Same POV — facing the Dealer across the table. Your visual identity has shifted to reflect this. |
| **DEALER** | The same Dealer from Rounds 1–3. Carries over their exact health state from the end of Round 3. |

---

### Health

| Entity | HP |
|--------|----|
| **Ghost (You)** | 1 Glowing Orb |
| **Dealer** | ∞ (Infinite — cannot be killed in Round 4) |

- The Ghost's single Glowing Orb represents your entire existence in this round. It is displayed visually as a single glowing orb on your side of the table.
- If the Dealer fires a **live shell at you**, the orb shatters and disappears. **Permanent death. Restart the entire game from Round 1.**
- The Dealer has infinite health. Shooting the Dealer does nothing — dealing damage to them is irrelevant and impossible to leverage. They cannot be eliminated.

---

### Barrel Composition

- **Total shells:** 8 (fixed)
- **Live shells:** Maximum 2
- **Blank shells:** Remaining slots filled with blanks (minimum 6)
- Shell composition is randomized within these constraints and configurable.
- At the start of Round 4, the full barrel composition is revealed to both players for **3 seconds** before play begins.

---

### Win Condition
The Ghost wins Round 4 by **firing the shotgun at themselves when the current shell is live**. This represents the defibrillator delivering enough charge to restart the heart — a resurrection through self-inflicted shock.

### Lose Conditions
The Ghost loses Round 4 (and the entire run — restart from Round 1) if:
1. The **Dealer fires a live shell at the Ghost** — orb shatters, permanent death.
2. The **entire shell sequence is exhausted** (including any shells added via the +4 Card) without the Ghost successfully shooting themselves with a live shell — the window for resurrection closes, and the Ghost remains dead.

---

### Blank Shells in Round 4
Blank shells fired **at the Ghost pass through entirely** — they do nothing. The Ghost is not physical. However, blank shells fired by the Ghost **at the Dealer** also do nothing (Dealer has infinite health). Blanks are pure dead weight for both sides — neither player benefits from a blank connecting with any target. The only meaningful shells in Round 4 are **live shells**, and both players are competing for them.

---

### Items in Round 4

Both the Ghost and the Dealer receive **exactly one +4 Card each** at the start of Round 4. No other items are distributed in this round. The +4 Card is **single-use** — once played, it is gone. There are no refills.

---

### The +4 Card (New Item — Round 4 Exclusive)

**Inspired by the UNO +4 card.**

When used, the +4 Card inserts **4 new shells at the top of the barrel sequence** — meaning they are placed immediately before the current shell. All existing shells shift back by 4 positions. The 4 added shells always consist of exactly:
- **3 blank shells**
- **1 live shell**
...in a randomized order among the 4.

**Barrel overflow rule:** The barrel has a maximum capacity of 8 shells. If using the +4 Card would push the total beyond 8, the shells at the **bottom of the sequence** (furthest from being fired) are discarded until the total is back to 8. This means using the +4 Card recklessly could discard a live shell that was sitting deep in the barrel — a potentially catastrophic mistake for the Ghost.

**Strategic implications:**
- For the **Ghost**: use the +4 Card when both live shells have already been fired or discarded and the barrel is running dry — it is a lifeline, a "one last chance" to get a live shell back into play before the sequence ends.
- For the **Dealer**: use the +4 Card to bury the current live shell deeper in the sequence — adding 4 shells on top of a live shell that was about to reach the front pushes it further away, buying time to find and fire it at the Ghost first.
- Both players know the composition of the added shells (always 3 blank + 1 live) — there is no hidden information about what the +4 Card adds. The uncertainty is only in the **order** of the 4 added shells.

---

### Dealer AI Behaviour — Round 4

The Dealer understands the rules of Round 4 from the start:
- **Blanks are useless against the Ghost** → the Dealer never intentionally fires a blank at the Ghost. When the current shell is blank, the Dealer shoots themselves (same as self-blank logic in earlier rounds — preserves their turn flow).
- **Primary objective:** find live shells and fire them at the Ghost as fast as possible. One hit ends the game.
- **+4 Card usage:** the Dealer uses the +4 Card when a live shell is close to the front of the barrel and about to be accessible to the Ghost — inserting 4 shells on top buries it and resets the race.
- The Dealer does not use the +4 Card recklessly — it checks whether using it would discard an existing live shell via overflow before deciding.

---

### Winning Round 4 — What Happens Next

If the Ghost successfully shoots themselves with a live shell:
- A resurrection animation plays.
- The player is returned to **Round 3 from the beginning**.
- Both the player's and the Dealer's health and items are **fully reset** to Round 3 starting values:
  - Player: 4 regular + 2 faded charges, 4 items
  - Dealer: 4 regular + 2 faded charges, 4 items
- The **Ghost Ally** now appears behind the Dealer for the entirety of this Round 3 replay (see below).

---

## RESURRECTED ROUND 3 — "Second Chance"

### Overview
Round 3 is replayed from the start with full health and items for both sides. Everything resets to Round 3 defaults. However, one thing is different: **the Ghost Ally now stands permanently behind the Dealer**, visible only to you. The Dealer is completely unaware of its presence.

You defeated death. The ghost community supports you now.

---

### The Ghost Ally — "Whisper"

Before **every one of your turns** in this replayed Round 3, the Ghost Ally briefly reveals the **next shell in the barrel** — not the current one, but the one after it. This is shown as a subtle visual flash (a whisper from the other side) before your turn begins.

**What this means practically:**
- You always know what is coming **after** your current action.
- This informs whether to shoot, use an item, or play defensively.
- For example: if the current shell is live and you know the next shell is also live, you can plan two moves ahead. If the current shell is blank and the next is live, you know exactly what the Dealer is walking into on their next turn.

**Boundaries:**
- The whisper reveals only the **next shell** — not the full barrel, not two ahead.
- It activates **only before your turns**, not the Dealer's.
- It is **permanent for the entire replayed Round 3** — it does not expire or have limited uses.
- It requires no action or item to activate — it is passive and automatic.

**Why this is balanced:**
The Ghost Ally gives you a one-shell lookahead, which is meaningful but not overwhelming. You still need to play well, use items correctly, and manage your charges. The Dealer is not handicapped — it plays at full strength. The whisper simply ensures you are never completely blind, which feels earned after the ordeal of Round 4.

---

### Win Condition — Resurrected Round 3
Same as normal Round 3: deplete the Dealer's health to zero. You are declared the winner. The Ghost Ally's assistance does not change the win condition — it only makes the path to it slightly more informed.

### Death Condition — Resurrected Round 3
If you die in this replayed Round 3, **you do not get another Round 4**. You restart the entire game from Round 1. Round 4 was your one shot at resurrection — you already used it.

---

## SUMMARY TABLE

| | Round 4 (Ghost Level) | Resurrected Round 3 |
|---|---|---|
| **Player identity** | Ghost | Human (resurrected) |
| **Player HP** | 1 Glowing Orb | 4 regular + 2 faded charges |
| **Dealer HP** | ∞ Infinite | 4 regular + 2 faded charges |
| **Barrel** | 8 shells, max 2 live | Randomized, min 3, configurable |
| **Items** | 1x +4 Card each | 4 items each (standard Round 3 pool) |
| **Special mechanic** | +4 Card, barrel overflow | Ghost Ally whisper (next shell revealed before your turn) |
| **Win condition** | Shoot yourself with a live shell | Deplete Dealer's health |
| **Lose condition** | Dealer hits you with live shell OR barrel exhausted without resurrection | Die to the Dealer |
| **Death consequence** | Restart from Round 1 | Restart from Round 1 (no second Round 4) |

---

## OPEN QUESTIONS / TO EXPERIMENT DURING PLAYTESTING

- Whether max 2 live shells in Round 4 is the right tension — could experiment with exactly 1 live shell for extreme tension or 3 for more opportunities
- Whether the Ghost Ally whisper should flash for 1 second, 2 seconds, or remain visible until you act
- Whether dying in Resurrected Round 3 should restart from Round 1 or Round 3 (currently: Round 1)

---

*Document version: v1.1 — +4 Card confirmed as exactly one each, single-use*
*Last updated: March 2026*
