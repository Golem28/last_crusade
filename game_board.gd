extends GridContainer

class_name GameBoard

const ENEMY_CARD_SCENE := preload("res://Components/card.tscn")

func _ready() -> void:
	add_to_group("game_board")
	_configure_zones()
	_spawn_enemies()
	GameManager.turn_ended.connect(enemies_attack)
	GameManager.row_topic_changed.connect(_on_topic_changed)
	GameManager.start_turn()

## Enemies the given player card may attack this turn.
## Ranged cards can hit any enemy; melee cards hit the most-front living
## enemy in each column.
func get_attackable_targets(attacker: Card) -> Array[Card]:
	var enemies := get_enemy_cards()
	if attacker.has_range:
		return enemies
	return _front_of_each_column(enemies)

## True when no friendly card is closer to the enemy side in the same
## column. Melee cards may only attack from the front of a column; if the
## card in front of them dies they take its place.
func is_front_of_column(card: Card) -> bool:
	var zone := card.get_drop_zone()
	if zone == null:
		return false
	var rank := zone.get_front_rank()
	var peers := get_enemy_cards() if card.is_enemy else get_player_cards()
	for other in peers:
		if other == card:
			continue
		var other_zone := other.get_drop_zone()
		if other_zone != null and other_zone.column == zone.column \
				and other_zone.get_front_rank() < rank:
			return false
	return true

## One target per column: the enemy closest to the player's side. When a
## front-line card dies, the card behind it in the same column becomes the
## target instead.
func _front_of_each_column(enemies: Array[Card]) -> Array[Card]:
	var result: Array[Card] = []
	for lane in 3:
		var best: Card = null
		var best_rank := 99
		for enemy in enemies:
			var zone := enemy.get_drop_zone()
			if zone == null or zone.column != lane:
				continue
			var rank := zone.get_front_rank()
			if rank < best_rank:
				best_rank = rank
				best = enemy
		if best != null:
			result.append(best)
	return result

func _on_topic_changed(topic: int) -> void:
	for zone in get_zones():
		zone.set_topic_highlight(zone.get_drop_zone_type() == topic)

func _configure_zones() -> void:
	for i in get_child_count():
		(get_child(i) as DropZone).configure(i)

func _spawn_enemies() -> void:
	for zone in get_enemy_zones():
		var card := ENEMY_CARD_SCENE.instantiate() as Card
		card.is_enemy = true
		card.card_data = _enemy_template(zone)
		zone.add_child(card)

func _enemy_template(zone: DropZone) -> Dictionary:
	match zone.get_drop_zone_type():
		DropZone.ZONE_TYPE.FLANK:
			return {
				"name": "Brawler",
				"front_label": "Melee 1",
				"support_label": "Melee 1",
				"range_label": "Melee 1",
				"attack": 1,
				"health": 6,
				"has_range": false,
			}
		DropZone.ZONE_TYPE.REAR:
			return {
				"name": "Archer",
				"front_label": "Ranged 2",
				"support_label": "Ranged 2",
				"range_label": "Ranged 2",
				"attack": 2,
				"health": 4,
				"has_range": true,
			}
		_:
			return {
				"name": "Grunt",
				"front_label": "Melee 2",
				"support_label": "Melee 2",
				"range_label": "Melee 2",
				"attack": 2,
				"health": 5,
				"has_range": false,
			}

func get_zones() -> Array[DropZone]:
	var zones: Array[DropZone] = []
	for child in get_children():
		if child is DropZone:
			zones.append(child as DropZone)
	return zones

func get_enemy_zones() -> Array[DropZone]:
	return get_zones().filter(func(z: DropZone): return z.is_enemy())

func get_player_zones() -> Array[DropZone]:
	return get_zones().filter(func(z: DropZone): return z.is_player())

func get_cards() -> Array[Card]:
	var cards: Array[Card] = []
	for zone in get_zones():
		for child in zone.get_children():
			if child is Card and is_instance_valid(child):
				cards.append(child as Card)
	return cards

func get_enemy_cards() -> Array[Card]:
	return get_cards().filter(func(c: Card): return c.is_enemy)

func get_player_cards() -> Array[Card]:
	return get_cards().filter(func(c: Card): return not c.is_enemy)

## Called on every turn end. Only up to two enemy cards standing in the
## current row topic may attack; if no player card is on the board, nothing
## happens.
func enemies_attack() -> void:
	var targets := get_player_cards()
	if targets.is_empty():
		return

	var topic := GameManager.row_topic
	var attacking := 0
	for enemy in get_enemy_cards():
		if attacking >= GameManager.ENEMY_ATTACK_LIMIT:
			break
		if enemy.get_drop_zone().get_drop_zone_type() != topic:
			continue
		var target := _enemy_target(enemy, targets)
		if target == null:
			continue
		target.take_damage(enemy.attack)
		attacking += 1

func _enemy_target(enemy: Card, targets: Array[Card]) -> Card:
	# Ranged enemies can attack from anywhere. Melee enemies only attack
	# when they are standing at the front of their column; a flank card
	# steps up when the front card in front of it dies.
	if not enemy.has_range and not is_front_of_column(enemy):
		return null
	return _most_front_card(targets)

func _most_front_card(cards: Array[Card]) -> Card:
	var best: Card = null
	var best_rank := 99
	for card in cards:
		var zone := card.get_drop_zone()
		if zone == null:
			continue
		var rank := zone.get_front_rank()
		if rank < best_rank:
			best_rank = rank
			best = card
	return best
