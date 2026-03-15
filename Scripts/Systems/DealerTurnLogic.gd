## DealerTurnLogic.gd
## AI behaviour evolves across rounds:
##   Round 0 — pure probability (no items)
##   Round 1 — item priority queue before shooting
##   Round 2 — same + cable-cut awareness
extends Node

# Injected by MainScene
var gsm: Node
var shotgun: Node
var player: Node
var dealer: Node
var item_system: Node

# Set after using Magnifying Glass this turn — so AI acts on the revealed info
var _peeked_shell: String = ""


func take_turn() -> void:
	_peeked_shell = ""
	var round_idx: int = gsm.round_system.current_round

	# Round 4 (Ghost) — completely different AI
	if gsm.is_ghost_round:
		_ghost_round_turn()
		return

	if round_idx >= 1 and item_system:
		_use_items_round2(round_idx)

	_shoot_decision()


# ── Ghost Round 4 AI ──────────────────────────────────────────────────

func _ghost_round_turn() -> void:
	# Step 1: Consider using the +4 Card
	_consider_plus4_card()

	# Step 2: Peek if we have a magnifying glass (we won't in ghost round,
	# but keep it defensive in case future items are added)
	_peeked_shell = ""

	# Step 3: Shooting decision — find live shells and fire at Ghost
	var p_live: float = _live_probability()

	# If we know the current shell:
	if _peeked_shell == "LIVE":
		print("[Dealer/Ghost] CONFIRMED LIVE → shoots PLAYER (Ghost)")
		gsm.dealer_shoot("player")
		return

	if _peeked_shell == "BLANK":
		# Self-blank to keep turn (blanks do nothing to Ghost anyway)
		print("[Dealer/Ghost] CONFIRMED BLANK → shoots SELF")
		gsm.dealer_shoot("dealer")
		return

	# Probability-based: be aggressive
	if p_live > 0.3:
		print("[Dealer/Ghost] p_live=%.2f → shoots PLAYER (Ghost)" % p_live)
		gsm.dealer_shoot("player")
	else:
		# Self-shoot to cycle through blanks faster
		print("[Dealer/Ghost] p_live=%.2f → shoots SELF (cycling blanks)" % p_live)
		gsm.dealer_shoot("dealer")


func _consider_plus4_card() -> void:
	if not item_system:
		return
	var items: Array = item_system.dealer_items.duplicate()
	for item in items:
		if item.item_name != "+4 Card":
			continue

		# Strategy: use +4 Card when a live shell is near the front
		# (positions 0-1) and the Ghost could access it on their next turn.
		# This buries the live shell deeper.
		var front_shell: String = shotgun.peek_next()
		var shells_remaining: int = shotgun.remaining_count()

		# Don't use if only 1-2 shells left (would overflow discard too many)
		if shells_remaining <= 2:
			continue

		# Check if using the card would discard a live shell from the back
		var would_discard_live: bool = false
		if shells_remaining + 4 > 8:
			var overflow_count: int = (shells_remaining + 4) - 8
			# Check the last `overflow_count` shells for lives
			for i in range(shells_remaining - overflow_count, shells_remaining):
				if i >= 0 and i < shotgun.shells.size() and shotgun.shells[i] == "LIVE":
					would_discard_live = true
					break

		# Use +4 Card if live is at front AND we won't lose a live shell
		if front_shell == "LIVE" and not would_discard_live:
			print("[Dealer/Ghost] Using +4 Card to bury live shell at front")
			item_system.dealer_use_item(item)
			return


# ── Item usage (Rounds 2 & 3) ─────────────────────────────────────────

func _use_items_round2(round_idx: int) -> void:
	var items: Array = item_system.dealer_items.duplicate()

	for item in items:
		var used := false
		match item.item_name:
			"Magnifying Glass":
				# Peek if uncertain (avoid wasting when we already know)
				if _peeked_shell == "":
					item_system.dealer_use_item(item)
					_peeked_shell = shotgun.peek_next()
					used = true

			"Cigarette":
				# Heal when at low regular HP and cables not cut
				if dealer.regular_charges <= 1 and not dealer.cables_cut:
					item_system.dealer_use_item(item)
					used = true

			"Handsaw":
				# Use handsaw when we know (or suspect) it's a live shell
				var p_live: float = _live_probability()
				var confirmed_live: bool = _peeked_shell == "LIVE"
				if confirmed_live or p_live >= 0.75:
					item_system.dealer_use_item(item)
					used = true

			"Handcuffs":
				# Cuff player when they're at 1 HP or we have confirmed live with bonus damage
				if player.current_hp == 1 or (gsm.shotgun_damage == 2 and _live_probability() > 0.5):
					item_system.dealer_use_item(item)
					used = true

			"Soda":
				# Eject when we know it's live but don't want to take the risk of shooting self,
				# OR when blank probability is high and we're looking for a live shell
				var confirmed_blank: bool = _peeked_shell == "BLANK"
				if confirmed_blank:
					item_system.dealer_use_item(item)
					_peeked_shell = ""  # After eject, peek info is stale
					used = true

		# Round 3 extra logic: cable-cut awareness
		if round_idx >= 2 and not used:
			if item.item_name == "Soda" and player.cables_cut:
				# If player cables cut, we want live shells — eject blanks
				if _peeked_shell == "BLANK":
					item_system.dealer_use_item(item)
					_peeked_shell = ""


# ── Shooting decision ─────────────────────────────────────────────────

func _shoot_decision() -> void:
	var p_live: float = _live_probability()
	var confirmed_live:  bool = _peeked_shell == "LIVE"
	var confirmed_blank: bool = _peeked_shell == "BLANK"

	if confirmed_live:
		# Always shoot player with confirmed live
		print("[Dealer] CONFIRMED LIVE → shoots PLAYER")
		gsm.dealer_shoot("player")
		return

	if confirmed_blank:
		# Self-blank to keep turn
		print("[Dealer] CONFIRMED BLANK → shoots SELF")
		gsm.dealer_shoot("dealer")
		return

	# Probability-based decision
	if p_live > 0.5:
		print("[Dealer] p_live=%.2f → shoots PLAYER" % p_live)
		gsm.dealer_shoot("player")
	else:
		print("[Dealer] p_live=%.2f → shoots SELF (blank likely)" % p_live)
		gsm.dealer_shoot("dealer")


func _live_probability() -> float:
	var total: int = shotgun.remaining_count()
	if total == 0:
		return 0.0
	return float(shotgun.live_count()) / float(total)
