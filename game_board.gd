extends GridContainer

class_name GameBoard

const ENEMY_CARD_SCENE := preload("res://Components/card.tscn")

func _ready() -> void:
	_configure_zones()
	_spawn_enemies()
	GameManager.turn_ended.connect(enemies_attack)
	GameManager.row_topic_changed.connect(_on_topic_changed)
	GameManager.start_turn()

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
	# when they are standing on the enemy front line.
	if not enemy.has_range and enemy.get_drop_zone().get_front_rank() != 0:
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
