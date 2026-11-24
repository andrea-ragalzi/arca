extends ArcaInteractionPoint
## One-shot ammo or medkit supply. The room owns the shared collect feedback.

enum Kind { AMMO, MEDKIT }

@export var kind: Kind = Kind.AMMO
## Reserve rounds for AMMO, hit points for MEDKIT.
@export var amount: int = 12

func get_prompt(_room: Node) -> String:
	if kind == Kind.AMMO:
		return "Collect %d rounds" % amount
	return action_text

func interact(room: Node) -> bool:
	if not enabled:
		return false
	match kind:
		Kind.AMMO:
			room.player.ammo_component.add_reserve(amount)
			room._collect_supply(self, "AMMO COLLECTED / +%d reserve" % amount)
			return true
		Kind.MEDKIT:
			var health: ArcaHealth = room.player.health_component
			var previous_health: int = health.current
			if not health.heal(amount):
				room._notify("HEALTH FULL / Medkit left for later")
				return false
			room._collect_supply(self, "MEDKIT USED / +%d HP" % (health.current - previous_health))
			return true
	return false
