extends Node

const SAVE_PATH := "user://save.data"

const UPGRADE_COST := {
	"speed": 30,
	"kiwi": 25,
	"palitos_base": 40,
	"shield_duration": 30,
	"turbo_duration": 30,
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
	"tero": { "name": "Tero", "cost": 15, "Bonus": "+ velocidad", "Penalidad": "Aleteo lento" },
	"golondrina": { "name": "Golondrina", "cost": 15, "Bonus": "+15% kiwi", "Penalidad": "-50% palitos" },
	"carpintero": { "name": "Carpintero", "cost": 15, "Bonus": "2 vidas", "Penalidad": "- velocidad" },
	"premio_pajarero": { "name": "???", "cost": -1, "Bonus": "—", "Penalidad": "—" },
}

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
	"collector": { "name": "Coleccionista", "cond": "bolas_total", "idx": 3, "levels": [
		{ "target": 3, "desc": "3 barro total", "reward_type": "bolas", "reward_amount": 1 },
		{ "target": 5, "desc": "5 barro total", "reward_type": "bolas", "reward_amount": 2 },
		{ "target": 10, "desc": "10 barro total", "reward_type": "bolas", "reward_amount": 3 },
	]},
	"persistent": { "name": "Persistente", "cond": "deaths", "idx": 4, "levels": [
		{ "target": 20, "desc": "Morir 20 veces", "reward_type": "palitos", "reward_amount": 30 },
		{ "target": 35, "desc": "Morir 35 veces", "reward_type": "palitos", "reward_amount": 50 },
		{ "target": 50, "desc": "Morir 50 veces", "reward_type": "palitos", "reward_amount": 80 },
	]},
	"storm_survivor": { "name": "Tormentero", "cond": "storms", "idx": 5, "levels": [
		{ "target": 3, "desc": "3 tormentas", "reward_type": "bolas", "reward_amount": 1 },
		{ "target": 10, "desc": "10 tormentas", "reward_type": "bolas", "reward_amount": 3 },
		{ "target": 25, "desc": "25 tormentas", "reward_type": "bolas", "reward_amount": 5 },
	]},
	"buyer": { "name": "Comprador", "cond": "total_upgrades_bought", "idx": 6, "levels": [
		{ "target": 3, "desc": "Comprar 3 mejoras", "reward_type": "palitos", "reward_amount": 20 },
		{ "target": 7, "desc": "Comprar 7 mejoras", "reward_type": "palitos", "reward_amount": 50 },
		{ "target": 15, "desc": "Comprar 15 mejoras", "reward_type": "palitos", "reward_amount": 100 },
	]},
	"calma_survivor": { "name": "Sereno", "cond": "calmas_survived", "idx": 7, "levels": [
		{ "target": 3, "desc": "3 calmas", "reward_type": "bolas", "reward_amount": 1 },
		{ "target": 10, "desc": "10 calmas", "reward_type": "bolas", "reward_amount": 3 },
	]},
	"maxed_out": { "name": "Al Máximo", "cond": "all_maxed", "idx": 8, "levels": [
		{ "target": 1, "desc": "Todas las mejoras en nivel 8", "reward_type": "bolas", "reward_amount": 5 },
	]},
	"birder": { "name": "Pajarero", "cond": "all_birds", "idx": 9, "levels": [
		{ "target": 1, "desc": "Desbloquear todos los pájaros", "reward_type": "unlock_bird", "reward_amount": 0 },
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
var kiwi_accepts := 0
var total_upgrades_bought := 0
var calmas_survived := 0

func _ready() -> void:
	load_data()

func get_upgrade_level(key: String) -> int:
	return upgrades.get(key, 0)

func get_upgrade_cost(key: String) -> int:
	var level := get_upgrade_level(key)
	var max_lv: int = UPGRADE_MAX_LEVEL.get(key, 8)
	if level >= max_lv:
		return -1
	return UPGRADE_COST[key] * int(pow(2, level))

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
			return { "flap_mult": 0.6, "speed_mult": 2.0, "kiwi_bonus": 0.0, "palitos_mult": 1.0, "extra_lives": 0 }
		"golondrina":
			return { "flap_mult": 1.0, "speed_mult": 1.0, "kiwi_bonus": 0.15, "palitos_mult": 0.5, "extra_lives": 0 }
		"carpintero":
			return { "flap_mult": 1.0, "speed_mult": 0.6, "kiwi_bonus": 0.0, "palitos_mult": 1.0, "extra_lives": 1 }
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
	return total

func add_bolas(amount: int) -> void:
	bolas_balance += amount
	bolas_total += amount
	save_data()

func accept_kiwi() -> Array:
	kiwi_accepts += 1
	var unlocked := check_achievements({})
	save_data()
	return unlocked

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
	save_data()

func add_palitos(amount: int) -> void:
	palitos_balance += amount
	save_data()

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
				for bid in ["hornero", "tero", "golondrina", "carpintero"]:
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
		if achieved:
			completed_achievements[id] = next_idx
			var rtype: String = level_data["reward_type"]
			var ramount: int = level_data["reward_amount"]
			if rtype == "bolas":
				bolas_balance += ramount
			elif rtype == "palitos":
				palitos_balance += ramount
			elif rtype == "unlock_bird":
				if not "premio_pajarero" in unlocked_birds:
					unlocked_birds.append("premio_pajarero")
			unlocked.append({ "id": id, "level": next_idx, "name": a["name"], "desc": level_data["desc"] })
	save_data()
	return unlocked

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
		_:
			return -1

func show_achievement_popup(info: Dictionary) -> void:
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	add_child(overlay)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.05, 0.85)
	bg.size = Vector2(350, 88)
	bg.position = Vector2(16, 16)
	bg.mouse_filter = Control.MOUSE_FILTER_PASS

	var name_lbl := Label.new()
	name_lbl.text = info["name"]
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	name_lbl.position = Vector2(0, 6)
	name_lbl.size = Vector2(350, 34)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var desc_lbl := Label.new()
	desc_lbl.text = info["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	desc_lbl.position = Vector2(0, 46)
	desc_lbl.size = Vector2(350, 32)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	bg.add_child(name_lbl)
	bg.add_child(desc_lbl)
	overlay.add_child(bg)

	bg.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.tween_property(bg, "modulate", Color(1, 1, 1, 1), 0.25)
	tween.tween_interval(2.0)
	tween.tween_property(bg, "modulate", Color(1, 1, 1, 0), 0.4)
	tween.tween_callback(overlay.queue_free)

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
		"kiwi_accepts": kiwi_accepts,
		"total_upgrades_bought": total_upgrades_bought,
		"calmas_survived": calmas_survived,
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
				var u = data.get("upgrades", {})
				if u.has("calandria") and not u.has("kiwi"):
					u["kiwi"] = u["calandria"]
					u.erase("calandria")
				upgrades = u
				var ca = data.get("completed_achievements", {})
				if ca is Array:
					var old : Array = ca
					completed_achievements = {}
					for aid in old:
						completed_achievements[aid] = 0
				else:
					completed_achievements = ca
			elif data is int:
				palitos_balance = data
				bolas_balance = 0
				upgrades = {}
