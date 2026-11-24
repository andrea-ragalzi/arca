class_name ArcaRaptorBehavior
extends Resource
## Tunable senses and decisions for a mission predator. Presentation stays on the skin.

@export_range(30.0, 360.0) var field_of_view: float = 150.0
@export_range(1.0, 30.0) var hearing_range: float = 13.0
@export_range(0.0, 1.0) var hearing_through_cover: float = 0.55
@export_range(0.2, 8.0) var memory_duration: float = 1.8
@export_range(0.5, 10.0) var search_duration: float = 3.2
@export_range(0.0, 3.0) var observation_duration: float = 0.78
@export_range(0.1, 1.0) var cautious_speed: float = 0.56
@export_range(0.0, 9.0) var flank_distance: float = 2.6
@export_range(0.0, 2.0) var retreat_duration: float = 0.76
@export_range(0.0, 30.0) var call_range: float = 15.0
@export_range(0.0, 8.0) var pounce_range: float = 4.4
@export_range(0.5, 12.0) var pounce_cooldown: float = 5.4
@export_range(0.0, 4.0) var max_leap_height: float = 1.20
@export_range(0.0, 4.0) var max_drop_height: float = 1.25

@export_group("Utility")
@export_range(0.0, 2.0) var curiosity := 0.60
@export_range(0.0, 2.0) var caution := 0.45
@export_range(0.0, 2.0) var aggression := 0.90
@export_range(0.0, 2.0) var flank_weight := 0.82
@export_range(0.0, 2.0) var jump_weight := 1.35
@export_range(0.0, 2.0) var retreat_weight := 1.15
@export_range(0, 60) var decision_hold_ticks := 12
