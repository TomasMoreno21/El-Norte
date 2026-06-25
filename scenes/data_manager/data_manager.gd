extends Node

const SAVE_PATH := "user://save.data"

const UPGRADE_COST := {
	"speed": 110,
	"kiwi": 90,
	"palitos_base": 150,
	"shield_duration": 100,
	"turbo_duration": 100,
}

const UPGRADE_COST_TABLE := {
	"speed": [200, 300, 500, 700, 1200, 2000, 3000, 5000],
	"kiwi": [150, 250, 400, 600, 1000, 1500, 2500, 4000],
	"palitos_base": [250, 400, 600, 1000, 1500, 2500, 4000, 6500],
	"shield_duration": [150, 250, 400, 700, 1000],
	"turbo_duration": [150, 250, 400, 700, 1000],
}

const UPGRADE_MAX_LEVEL := {
	"speed": 8,
	"kiwi": 8,
	"palitos_base": 8,
	"shield_duration": 5,
	"turbo_duration": 5,
}

const MAX_LEVEL := 8

const BIRDS := {
	"hornero": { "name": "Hornero", "cost": 0, "Bonus": "—", "Penalidad": "—" },
	"tero": { "name": "Tero", "cost": 45, "Bonus": "+40% velocidad", "Penalidad": "-15% palitos" },
	"golondrina": { "name": "Golondrina", "cost": 35, "Bonus": "+20% kiwi", "Penalidad": "-15% palitos" },
	"carpintero": { "name": "Carpintero", "cost": 25, "Bonus": "1 vida extra", "Penalidad": "-25% palitos" },
	"premio_pajarero": { "name": "Carancho", "cost": -1, "Bonus": "1 vida, +60% vel, +10% palitos", "Penalidad": "—" },
}

const DISTANCE_MILESTONES := [
	{ "target": 500, "reward": 10 },
	{ "target": 1000, "reward": 25 },
	{ "target": 2200, "reward": 75 },
	{ "target": 4600, "reward": 150 },
]

const RECORD_BOLAS := [
	{ "target": 500, "reward": 1 },
	{ "target": 1000, "reward": 2 },
	{ "target": 2200, "reward": 3 },
	{ "target": 4600, "reward": 5 },
]

const ACHIEVEMENTS := {
	"first_flight": { "name": "Primer Vuelo", "cond": "distance", "idx": 0, "levels": [
		{ "target": 100, "desc": "Llegar a 100m", "reward_type": "bolas", "reward_amount": 1 },
	]},
	"explorer": { "name": "Explorador", "cond": "distance", "idx": 1, "levels": [
		{ "target": 500, "desc": "Llegar a 500m", "reward_type": "bolas", "reward_amount": 1 },
	]},
	"fearless": { "name": "Sin Miedo", "cond": "distance", "idx": 2, "levels": [
		{ "target": 2000, "desc": "Llegar a 2000m", "reward_type": "palitos", "reward_amount": 80 },
	]},
	"llanura": { "name": "Llanuras", "cond": "distance", "idx": 12, "levels": [
		{ "target": 2200, "desc": "Llegar a las Llanuras", "reward_type": "bolas", "reward_amount": 2 },
	]},
	"norte": { "name": "Norte", "cond": "distance", "idx": 13, "levels": [
		{ "target": 4600, "desc": "Llegar al Norte (Puna)", "reward_type": "bolas", "reward_amount": 3 },
	]},
	"maraton": { "name": "Maratón", "cond": "distance", "idx": 17, "levels": [
		{ "target": 10000, "desc": "Llegar a 10000m", "reward_type": "bolas", "reward_amount": 5 },
	]},
	"collector": { "name": "Coleccionista", "cond": "bolas_total", "idx": 3, "levels": [
		{ "target": 3, "desc": "3 barro total", "reward_type": "palitos", "reward_amount": 100 },
		{ "target": 5, "desc": "5 barro total", "reward_type": "palitos", "reward_amount": 150 },
		{ "target": 10, "desc": "10 barro total", "reward_type": "palitos", "reward_amount": 200 },
	]},
	"ladron": { "name": "Ladrón", "cond": "bolas_total", "idx": 18, "levels": [
		{ "target": 1000, "desc": "1000 barros en total", "reward_type": "palitos", "reward_amount": 500 },
	]},
	"rico": { "name": "Rico", "cond": "palitos_balance", "idx": 15, "levels": [
		{ "target": 1000, "desc": "Tener 1000 palitos", "reward_type": "bolas", "reward_amount": 2 },
		{ "target": 3000, "desc": "Tener 3000 palitos", "reward_type": "bolas", "reward_amount": 4 },
		{ "target": 8000, "desc": "Tener 8000 palitos", "reward_type": "bolas", "reward_amount": 6 },
	]},
	"buyer": { "name": "Comprador", "cond": "total_upgrades_bought", "idx": 6, "levels": [
		{ "target": 3, "desc": "Comprar 3 mejoras", "reward_type": "palitos", "reward_amount": 20 },
		{ "target": 7, "desc": "Comprar 7 mejoras", "reward_type": "palitos", "reward_amount": 50 },
		{ "target": 15, "desc": "Comprar 15 mejoras", "reward_type": "palitos", "reward_amount": 100 },
	]},
	"birder": { "name": "Pajarero", "cond": "all_birds", "idx": 9, "levels": [
		{ "target": 1, "desc": "Desbloquear todos los pájaros", "reward_type": "unlock_bird", "reward_amount": 0 },
	]},
	"pampeano": { "name": "Pampeano", "cond": "all_birds_5000", "idx": 20, "levels": [
		{ "target": 4, "desc": "5000m con cada pájaro", "reward_type": "bolas", "reward_amount": 4 },
	]},
	"por_los_pelos": { "name": "Por los Pelos", "cond": "revives_used", "idx": 14, "levels": [
		{ "target": 1, "desc": "Usar 1 revive", "reward_type": "palitos", "reward_amount": 30 },
		{ "target": 5, "desc": "Usar 5 revives", "reward_type": "palitos", "reward_amount": 60 },
		{ "target": 10, "desc": "Usar 10 revives", "reward_type": "palitos", "reward_amount": 100 },
	]},
	"storm_survivor": { "name": "Tormentero", "cond": "storms", "idx": 5, "levels": [
		{ "target": 3, "desc": "3 tormentas", "reward_type": "bolas", "reward_amount": 1 },
		{ "target": 10, "desc": "10 tormentas", "reward_type": "bolas", "reward_amount": 3 },
		{ "target": 25, "desc": "25 tormentas", "reward_type": "bolas", "reward_amount": 5 },
	]},
	"calma_survivor": { "name": "Sereno", "cond": "calmas_survived", "idx": 7, "levels": [
		{ "target": 3, "desc": "3 calmas", "reward_type": "bolas", "reward_amount": 1 },
		{ "target": 10, "desc": "10 calmas", "reward_type": "bolas", "reward_amount": 3 },
	]},
	"persistent": { "name": "Persistente", "cond": "deaths", "idx": 4, "levels": [
		{ "target": 20, "desc": "Morir 20 veces", "reward_type": "palitos", "reward_amount": 30 },
		{ "target": 35, "desc": "Morir 35 veces", "reward_type": "palitos", "reward_amount": 50 },
		{ "target": 50, "desc": "Morir 50 veces", "reward_type": "palitos", "reward_amount": 80 },
	]},
	"veterano": { "name": "Veterano", "cond": "deaths", "idx": 19, "levels": [
		{ "target": 100, "desc": "Morir 100 veces", "reward_type": "bolas", "reward_amount": 3 },
	]},
	"maxed_out": { "name": "Al Máximo", "cond": "all_maxed", "idx": 8, "levels": [
		{ "target": 1, "desc": "Todas las mejoras en nivel 8", "reward_type": "bolas", "reward_amount": 5 },
	]},
	"multiuso": { "name": "Multiuso", "cond": "bird_uses", "idx": 16, "levels": [
		{ "target": 2, "desc": "Usar 2 pájaros distintos", "reward_type": "palitos", "reward_amount": 40 },
		{ "target": 3, "desc": "Usar 3 pájaros distintos", "reward_type": "palitos", "reward_amount": 80 },
		{ "target": 4, "desc": "Usar los 4 pájaros", "reward_type": "bolas", "reward_amount": 5 },
	]},
	"trato_hecho": { "name": "Trato Hecho", "cond": "kiwi_accepts", "idx": 10, "levels": [
		{ "target": 20, "desc": "Aceptar 20 ofertas del kiwi", "reward_type": "none", "reward_amount": 0 },
	]},
	"rey_tormentas": { "name": "Rey de Tormentas", "cond": "storms_in_run", "idx": 11, "levels": [
		{ "target": 6, "desc": "6 tormentas en una partida", "reward_type": "none", "reward_amount": 0 },
	]},
}

var palitos_balance := 0
var bolas_balance := 0
var upgrades := {}
var unlocked_birds := ["hornero"]
var active_bird := "hornero"
var bolas_total := 0
var deaths := 0
var storms_survived := 0
var max_distance := 0
var completed_achievements := {}
var pending_rewards := {}
var kiwi_accepts := 0
var total_upgrades_bought := 0
var calmas_survived := 0
var revives_used := 0
var used_birds := []
var first_milestones_claimed := []
var record_bolas_claimed := []
var tutorial_done := false
var welcome_bonus_given := false
var explored_biomes := []
var bird_max_distances := {}
var reduce_motion := false
var sound_enabled := true
var minimap_visible := false

func _ready() -> void:
	load_data()
	_grant_welcome_bonus()

func _grant_welcome_bonus() -> void:
	if not welcome_bonus_given:
		welcome_bonus_given = true
		palitos_balance += 50
		save_data()

func claim_explorer_bonus(biome_idx: int) -> int:
	if biome_idx in explored_biomes:
		return 0
	explored_biomes.append(biome_idx)
	var bonus := 0
	match biome_idx:
		1: bonus = 30
		2: bonus = 60
	palitos_balance += bonus
	save_data()
	return bonus

func get_upgrade_level(key: String) -> int:
	return upgrades.get(key, 0)

func get_upgrade_cost(key: String) -> int:
	var level := get_upgrade_level(key)
	if not key in UPGRADE_COST_TABLE:
		return -1
	var table: Array = UPGRADE_COST_TABLE[key]
	if level >= table.size():
		return -1
	return table[level]

func buy_upgrade(key: String) -> Array:
	var level := get_upgrade_level(key)
	var max_lv: int = UPGRADE_MAX_LEVEL.get(key, 8)
	if level >= max_lv:
		return []
	var cost := get_upgrade_cost(key)
	if palitos_balance < cost:
		return []
	palitos_balance -= cost
	upgrades[key] = level + 1
	total_upgrades_bought += 1
	var nuevos := check_achievements({})
	save_data()
	return nuevos

func is_bird_unlocked(bird: String) -> bool:
	return bird in unlocked_birds

func unlock_bird(bird: String) -> Array:
	if is_bird_unlocked(bird):
		return []
	var cost = BIRDS[bird]["cost"]
	if bolas_balance < cost:
		return []
	bolas_balance -= cost
	unlocked_birds.append(bird)
	var nuevos := check_achievements({})
	save_data()
	return nuevos

func get_bird_modifiers() -> Dictionary:
	match active_bird:
		"tero":
			return { "flap_mult": 0.72, "speed_mult": 1.4, "kiwi_bonus": 0.0, "palitos_mult": 0.85, "extra_lives": 0 }
		"golondrina":
			return { "flap_mult": 1.1, "speed_mult": 1.0, "kiwi_bonus": 0.20, "palitos_mult": 0.85, "extra_lives": 0 }
		"carpintero":
			return { "flap_mult": 1.0, "speed_mult": 0.9, "kiwi_bonus": 0.0, "palitos_mult": 0.75, "extra_lives": 1 }
		"premio_pajarero":
			return { "flap_mult": 1.0, "speed_mult": 1.6, "kiwi_bonus": 0.0, "palitos_mult": 1.1, "extra_lives": 1 }
		_:
			return { "flap_mult": 1.0, "speed_mult": 1.0, "kiwi_bonus": 0.0, "palitos_mult": 1.0, "extra_lives": 0 }

func select_bird(bird: String) -> void:
	if is_bird_unlocked(bird):
		active_bird = bird
		save_data()

func calculate_palitos_earned(distance: int) -> int:
	var rate := 1 + get_upgrade_level("palitos_base")
	var segments := distance / 10
	var total := segments * rate
	var mods := get_bird_modifiers()
	total = int(total * mods["palitos_mult"])
	var biome_mult := 1.0
	if distance > 4600:
		biome_mult = 2.0
	elif distance > 2200:
		biome_mult = 1.5
	total = int(total * biome_mult)
	return total

func add_bolas(amount: int) -> void:
	bolas_balance += amount
	bolas_total += amount
	save_data()

func claim_distance_milestones(distance: int) -> int:
	var total := 0
	for m in DISTANCE_MILESTONES:
		var t: int = m["target"]
		if distance >= t and not t in first_milestones_claimed:
			first_milestones_claimed.append(t)
			total += m["reward"]
	if total > 0:
		save_data()
	return total

func claim_record_bolas(distance: int, old_max: int) -> int:
	var total := 0
	if distance <= old_max:
		return 0
	for m in RECORD_BOLAS:
		var t: int = m["target"]
		if distance >= t and not t in record_bolas_claimed:
			record_bolas_claimed.append(t)
			total += m["reward"]
	if total > 0:
		bolas_balance += total
		bolas_total += total
		save_data()
	return total

func accept_kiwi() -> Array:
	kiwi_accepts += 1
	var unlocked := check_achievements({})
	save_data()
	return unlocked

func reset_achievements() -> void:
	completed_achievements = {}
	save_data()

func reset_data() -> void:
	palitos_balance = 0
	bolas_balance = 0
	upgrades = {}
	unlocked_birds = ["hornero"]
	active_bird = "hornero"
	bolas_total = 0
	deaths = 0
	storms_survived = 0
	max_distance = 0
	completed_achievements = {}
	kiwi_accepts = 0
	total_upgrades_bought = 0
	calmas_survived = 0
	revives_used = 0
	used_birds = []
	first_milestones_claimed = []
	record_bolas_claimed = []
	tutorial_done = false
	welcome_bonus_given = false
	explored_biomes = []
	save_data()

func mark_bird_used(bird: String) -> void:
	if not bird in used_birds:
		used_birds.append(bird)
		save_data()

func mark_bird_distance(bird: String, dist: int) -> Array:
	var prev: int = bird_max_distances.get(bird, 0)
	if dist > prev:
		bird_max_distances[bird] = dist
		save_data()
		return check_achievements({})
	return []

func add_palitos(amount: int) -> Array:
	palitos_balance += amount
	save_data()
	return check_achievements({})

func check_achievements(conditions: Dictionary) -> Array:
	var unlocked := []
	for id in ACHIEVEMENTS:
		var a = ACHIEVEMENTS[id]
		var current_level: int = completed_achievements.get(id, -1)
		var next_idx: int = current_level + 1
		if next_idx >= a["levels"].size():
			continue
		var level_data = a["levels"][next_idx]
		var achieved := false
		match a["cond"]:
			"distance":
				achieved = conditions.get("distance", 0) >= level_data["target"]
			"bolas_total":
				achieved = bolas_total >= level_data["target"]
			"deaths":
				achieved = deaths >= level_data["target"]
			"storms":
				achieved = storms_survived >= level_data["target"]
			"all_maxed":
				achieved = true
				for key in UPGRADE_COST:
					var max_lv: int = UPGRADE_MAX_LEVEL.get(key, 8)
					if get_upgrade_level(key) < max_lv:
						achieved = false
						break
			"all_birds":
				achieved = true
				for bid: String in ["hornero", "tero", "golondrina", "carpintero"]:
					if not bid in unlocked_birds:
						achieved = false
						break
			"kiwi_accepts":
				achieved = kiwi_accepts >= level_data["target"]
			"storms_in_run":
				achieved = conditions.get("storms_in_run", 0) >= level_data["target"]
			"total_upgrades_bought":
				achieved = total_upgrades_bought >= level_data["target"]
			"calmas_survived":
				achieved = calmas_survived >= level_data["target"]
			"revives_used":
				achieved = revives_used >= level_data["target"]
			"palitos_balance":
				achieved = palitos_balance >= level_data["target"]
			"bird_uses":
				achieved = used_birds.size() >= level_data["target"]
			"all_birds_5000":
				achieved = true
				for bid: String in ["hornero", "tero", "golondrina", "carpintero"]:
					if bird_max_distances.get(bid, 0) < 5000:
						achieved = false
						break
		if achieved:
			completed_achievements[id] = next_idx
			var rtype: String = level_data["reward_type"]
			var ramount: int = level_data["reward_amount"]
			pending_rewards[id + "_" + str(next_idx)] = { "rtype": rtype, "ramount": ramount }
			unlocked.append({ "id": id, "level": next_idx, "name": a["name"], "desc": level_data["desc"], "reward_type": rtype, "reward_amount": ramount })
	save_data()
	return unlocked

func claim_achievement_reward(info: Dictionary) -> void:
	var key: String = str(info["id"]) + "_" + str(info["level"])
	if key not in pending_rewards:
		return
	var rdata: Dictionary = pending_rewards.get(key, {})
	if rdata.is_empty():
		return
	var rtype: String = rdata.get("rtype", "")
	var ramount: int = rdata.get("ramount", 0)
	pending_rewards.erase(key)
	match rtype:
		"bolas":
			bolas_balance += ramount
		"palitos":
			palitos_balance += ramount
		"unlock_bird":
			if not "premio_pajarero" in unlocked_birds:
				unlocked_birds.append("premio_pajarero")
	save_data()

func _format_reward(rtype: String, ramount: int) -> String:
	match rtype:
		"bolas":
			return "+%d barro" % ramount
		"palitos":
			return "+%d palitos" % ramount
		"unlock_bird":
			return "¡Nuevo pájaro!"
		_:
			return ""

func get_current_value(cond: String) -> int:
	match cond:
		"distance":
			return max_distance
		"bolas_total":
			return bolas_total
		"deaths":
			return deaths
		"storms":
			return storms_survived
		"kiwi_accepts":
			return kiwi_accepts
		"total_upgrades_bought":
			return total_upgrades_bought
		"calmas_survived":
			return calmas_survived
		"revives_used":
			return revives_used
		"palitos_balance":
			return palitos_balance
		"bird_uses":
			return used_birds.size()
		"all_birds_5000":
			var count := 0
			for bid: String in ["hornero", "tero", "golondrina", "carpintero"]:
				if bird_max_distances.get(bid, 0) >= 5000:
					count += 1
			return count
		_:
			return -1

func clear_achievement_popups() -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	for c in scene.get_children():
		if c is CanvasLayer:
			c.queue_free()

func show_achievement_popup(info: Dictionary) -> void:
	var scene := get_tree().current_scene
	if not scene:
		return
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	overlay.process_mode = PROCESS_MODE_WHEN_PAUSED
	scene.add_child(overlay)

	var POPUP_H := 140
	var vp := get_viewport().get_visible_rect().size
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 0.85)
	bg.size = Vector2(350, POPUP_H)
	bg.position = Vector2(16, vp.y - POPUP_H - 16)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS

	var name_lbl := Label.new()
	name_lbl.text = info["name"]
	name_lbl.add_theme_font_size_override("font_size", 22)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	name_lbl.position = Vector2(0, 6)
	name_lbl.size = Vector2(350, 34)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc_lbl := Label.new()
	desc_lbl.text = info["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.position = Vector2(0, 42)
	desc_lbl.size = Vector2(350, 32)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	bg.add_child(name_lbl)
	bg.add_child(desc_lbl)
	overlay.add_child(bg)

	var btn := Button.new()
	btn.text = "Recoger"
	btn.size = Vector2(120, 36)
	btn.position = Vector2((350 - 120) / 2, 76)
	var theme := Theme.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.55, 0.45, 0.15)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	theme.set_stylebox("normal", "Button", style)
	theme.set_stylebox("hover", "Button", style)
	theme.set_stylebox("pressed", "Button", style)
	var style_hover := style.duplicate()
	style_hover.bg_color = Color(0.7, 0.55, 0.2)
	theme.set_stylebox("hover", "Button", style_hover)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_font_size("font_size", "Button", 18)
	btn.theme = theme
	bg.add_child(btn)

	bg.modulate = Color(1, 1, 1, 0)
	var tw := get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(bg, "modulate", Color(1, 1, 1, 1), 0.3)

	var claimed := false
	btn.pressed.connect(func():
		if claimed:
			return
		claimed = true
		claim_achievement_reward(info)
		AudioManager.play_sfx("achievement")
		var txt := _format_reward(info.get("reward_type", ""), info.get("reward_amount", 0))
		if not txt.is_empty():
			_show_floating_reward_text(overlay, txt)
		await get_tree().create_timer(0.8, false).timeout
		if is_instance_valid(overlay):
			overlay.queue_free()
	)

	while not claimed:
		await get_tree().process_frame
		if not is_instance_valid(overlay):
			break

func _show_floating_reward_text(overlay: CanvasLayer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.75, 0.06))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(350, 40)
	lbl.position = Vector2(0, 10)
	overlay.add_child(lbl)
	var tw := get_tree().create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(lbl, "position", lbl.position + Vector2(0, -40), 0.8)
	tw.parallel().tween_property(lbl, "modulate", Color(1, 1, 1, 0), 0.8)
	tw.tween_callback(lbl.queue_free)

func save_data() -> void:
	var data := {
		"palitos_balance": palitos_balance,
		"bolas_balance": bolas_balance,
		"upgrades": upgrades,
		"unlocked_birds": unlocked_birds,
		"active_bird": active_bird,
		"bolas_total": bolas_total,
		"deaths": deaths,
		"storms_survived": storms_survived,
		"max_distance": max_distance,
		"completed_achievements": completed_achievements,
		"pending_rewards": pending_rewards,
		"kiwi_accepts": kiwi_accepts,
		"total_upgrades_bought": total_upgrades_bought,
		"calmas_survived": calmas_survived,
		"revives_used": revives_used,
		"used_birds": used_birds,
		"first_milestones_claimed": first_milestones_claimed,
		"record_bolas_claimed": record_bolas_claimed,
		"tutorial_done": tutorial_done,
		"welcome_bonus_given": welcome_bonus_given,
		"explored_biomes": explored_biomes,
		"bird_max_distances": bird_max_distances,
		"reduce_motion": reduce_motion,
		"sound_enabled": sound_enabled,
		"minimap_visible": minimap_visible,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(data)

func load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				palitos_balance = data.get("palitos_balance", 0)
				bolas_balance = data.get("bolas_balance", 0)
				unlocked_birds = data.get("unlocked_birds", ["hornero"])
				active_bird = data.get("active_bird", "hornero")
				bolas_total = data.get("bolas_total", 0)
				deaths = data.get("deaths", 0)
				storms_survived = data.get("storms_survived", 0)
				max_distance = data.get("max_distance", 0)
				kiwi_accepts = data.get("kiwi_accepts", data.get("calandria_accepts", 0))
				total_upgrades_bought = data.get("total_upgrades_bought", 0)
				calmas_survived = data.get("calmas_survived", 0)
				revives_used = data.get("revives_used", 0)
				used_birds = data.get("used_birds", [])
				first_milestones_claimed = data.get("first_milestones_claimed", [])
				record_bolas_claimed = data.get("record_bolas_claimed", [])
				tutorial_done = data.get("tutorial_done", false)
				welcome_bonus_given = data.get("welcome_bonus_given", false)
				explored_biomes = data.get("explored_biomes", [])
				bird_max_distances = data.get("bird_max_distances", {})
				reduce_motion = data.get("reduce_motion", false)
				sound_enabled = data.get("sound_enabled", true)
				minimap_visible = data.get("minimap_visible", false)
				var u = data.get("upgrades", {})
				if u.has("calandria") and not u.has("kiwi"):
					u["kiwi"] = u["calandria"]
					u.erase("calandria")
				upgrades = u
				var 				ca = data.get("completed_achievements", {})
				if ca is Array:
					var old : Array = ca
					completed_achievements = {}
					for aid in old:
						completed_achievements[aid] = 0
				else:
					completed_achievements = ca
				pending_rewards = data.get("pending_rewards", {})
			elif data is int:
				palitos_balance = data
				bolas_balance = 0
				upgrades = {}
