extends Control

const GRID_W = 7
const GRID_H = 5
const TILE = 74
const HAND_SIZE = 5
const START_ENERGY = 3

const CARD_STRIKE = "strike"
const CARD_LANCE = "lance"
const CARD_DASH = "dash"
const CARD_GUARD = "guard"
const CARD_ENGAGE = "engage"
const CARD_HEAL = "heal"

var battlefield_texture: Texture2D = null
var token_textures: Dictionary = {}
var card_textures: Dictionary = {}

var rng := RandomNumberGenerator.new()
var energy := START_ENERGY
var turn := 1
var player_power := 0
var selected_card := -1
var message := "选择一张卡牌，再点击发光格子。"
var phase := "player"
var victory := false
var defeat := false

var draw_pile: Array = []
var discard_pile: Array = []
var hand: Array = []
var units: Array = []

var board_rect: Rect2 = Rect2()
var hand_rects: Array = []
var end_turn_rect: Rect2 = Rect2()
var restart_rect: Rect2 = Rect2()
var hover_card := -1
var anim_time := 0.0
var effects: Array = []

func _ready() -> void:
	rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_STOP
	load_art_assets()
	start_run()

func _process(delta: float) -> void:
	anim_time += delta
	for effect in effects:
		effect["age"] = effect["age"] + delta
	effects = effects.filter(func(effect): return effect["age"] < effect["duration"])
	if effects.size() > 0 or selected_card >= 0 or phase == "enemy" or hover_card >= 0:
		queue_redraw()

func load_art_assets() -> void:
	battlefield_texture = load_image_texture("res://assets/art/battlefield-academy-courtyard-1280x720.jpg")
	token_textures = {
		"hero": load_image_texture("res://assets/art/tokens/astra-hero.png"),
		"sword": load_image_texture("res://assets/art/tokens/blade-acolyte.png"),
		"mage": load_image_texture("res://assets/art/tokens/rune-flare.png"),
		"guard": load_image_texture("res://assets/art/tokens/shield-vow.png"),
	}
	card_textures = {
		CARD_STRIKE: load_image_texture("res://assets/art/cards/quick-slash.png"),
		CARD_LANCE: load_image_texture("res://assets/art/cards/radiant-lance.png"),
		CARD_DASH: load_image_texture("res://assets/art/cards/step-command.png"),
		CARD_GUARD: load_image_texture("res://assets/art/cards/guard-bloom.png"),
		CARD_ENGAGE: load_image_texture("res://assets/art/cards/engage-crest.png"),
		CARD_HEAL: load_image_texture("res://assets/art/cards/mend-light.png"),
	}

func load_image_texture(res_path: String) -> Texture2D:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(res_path))
	if err != OK:
		push_warning("Could not load art asset: %s" % res_path)
		return null
	return ImageTexture.create_from_image(image)

func start_run() -> void:
	energy = START_ENERGY
	turn = 1
	player_power = 0
	selected_card = -1
	phase = "player"
	victory = false
	defeat = false
	hover_card = -1
	effects.clear()
	message = "选择一张卡牌，再点击发光格子。"
	units = [
		{"id": "hero", "name": "阿斯特拉", "team": "player", "hp": 42, "max_hp": 42, "atk": 7, "pos": Vector2i(1, 2), "block": 0},
		{"id": "sword", "name": "赤刃侍从", "team": "enemy", "hp": 18, "max_hp": 18, "atk": 5, "pos": Vector2i(5, 1), "block": 0},
		{"id": "mage", "name": "符焰术士", "team": "enemy", "hp": 15, "max_hp": 15, "atk": 6, "pos": Vector2i(5, 3), "block": 0},
		{"id": "guard", "name": "誓盾卫士", "team": "enemy", "hp": 24, "max_hp": 24, "atk": 4, "pos": Vector2i(6, 2), "block": 0},
	]
	draw_pile = build_starter_deck()
	discard_pile = []
	hand = []
	draw_pile.shuffle()
	draw_cards(HAND_SIZE)
	queue_redraw()

func build_starter_deck() -> Array:
	return [
		card("迅捷斩", CARD_STRIKE, 1, "对相邻敌人造成7点伤害。"),
		card("迅捷斩", CARD_STRIKE, 1, "对相邻敌人造成7点伤害。"),
		card("辉光枪", CARD_LANCE, 2, "直线3格内造成9点伤害。"),
		card("战术步", CARD_DASH, 1, "移动至3格内空位。"),
		card("战术步", CARD_DASH, 1, "移动至3格内空位。"),
		card("守护绽放", CARD_GUARD, 1, "获得8点格挡。"),
		card("守护绽放", CARD_GUARD, 1, "获得8点格挡。"),
		card("纹章共鸣", CARD_ENGAGE, 2, "力量+2，并抽1张牌。"),
		card("愈光", CARD_HEAL, 1, "恢复6点生命。"),
	]

func card(title: String, kind: String, cost: int, text: String) -> Dictionary:
	return {"title": title, "kind": kind, "cost": cost, "text": text}

func draw_cards(count: int) -> void:
	for i in range(count):
		if draw_pile.is_empty():
			if discard_pile.is_empty():
				return
			draw_pile = discard_pile.duplicate()
			discard_pile.clear()
			draw_pile.shuffle()
		hand.append(draw_pile.pop_back())

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_background(size)
	board_rect = Rect2(Vector2(74, 96), Vector2(GRID_W * TILE, GRID_H * TILE))
	draw_board()
	draw_units()
	draw_enemy_intents()
	draw_side_panel(size)
	draw_hand(size)
	draw_top_bar(size)
	draw_effects()
	draw_overlays(size)

func draw_background(size: Vector2) -> void:
	if battlefield_texture != null:
		draw_texture_rect(battlefield_texture, Rect2(Vector2.ZERO, size), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#101832"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#071126", 0.22))
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 86)), Color("#071126", 0.48))
	draw_rect(Rect2(Vector2(0, size.y - 250), Vector2(size.x, 250)), Color("#071126", 0.38))

func draw_panel(rect: Rect2, fill: Color = Color("#111a33", 0.86), border: Color = Color("#9fd7ff", 0.25)) -> void:
	draw_rect(rect, Color("#030814", 0.35))
	draw_rect(rect.grow(-2), fill)
	draw_rect(rect.grow(-2), border, false, 2.0)

func draw_button(rect: Rect2, label: String, fill: Color, text_color: Color = Color("#101832")) -> void:
	draw_rect(rect, Color("#030814", 0.28))
	draw_rect(rect.grow(-2), fill)
	draw_rect(rect.grow(-2), Color("#ffffff", 0.24), false, 1.5)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, 24), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 16, text_color)

func draw_bar(rect: Rect2, ratio: float, fill: Color, label: String) -> void:
	var clamped_ratio: float = clampf(ratio, 0.0, 1.0)
	draw_rect(rect, Color("#071126", 0.86))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clamped_ratio, rect.size.y)), fill)
	draw_rect(rect, Color("#ffffff", 0.2), false, 1.0)
	draw_string(get_theme_default_font(), rect.position + Vector2(0, rect.size.y - 4), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, Color.WHITE)

func phase_name() -> String:
	if phase == "player":
		return "我方行动"
	if phase == "enemy":
		return "敌方行动"
	return "结算"

func draw_board() -> void:
	var valid_tiles: Array = get_valid_tiles()
	var threat_tiles: Array = get_enemy_threat_tiles()
	draw_panel(board_rect.grow(14), Color("#071126", 0.34), Color("#bfe8ff", 0.3))
	for y in range(GRID_H):
		for x in range(GRID_W):
			var cell_rect := tile_rect(Vector2i(x, y))
			var base := Color("#dff8ff", 0.14) if (x + y) % 2 == 0 else Color("#6acfff", 0.11)
			draw_rect(cell_rect, base)
			draw_rect(cell_rect, Color("#c8f4ff", 0.28), false, 1.4)
			if Vector2i(x, y) in threat_tiles:
				draw_rect(cell_rect.grow(-7), Color("#ff5f7d", 0.13))
				draw_rect(cell_rect.grow(-7), Color("#ff5f7d", 0.32), false, 1.5)
			if Vector2i(x, y) in valid_tiles:
				var pulse: float = 0.55 + 0.35 * sin(anim_time * 5.0)
				draw_rect(cell_rect.grow(-5), Color("#79f2c9", 0.18 + pulse * 0.16))
				draw_rect(cell_rect.grow(-5), Color("#79f2c9", 0.48 + pulse * 0.38), false, 3.0)

func draw_units() -> void:
	for unit in units:
		var unit_pos: Vector2i = unit["pos"]
		var center: Vector2 = tile_rect(unit_pos).get_center()
		var is_player: bool = unit["team"] == "player"
		var trim: Color = Color("#fff0a6") if is_player else Color("#ffd1dc")
		var token: Texture2D = token_textures.get(unit["id"])
		draw_circle(center + Vector2(0, 3), 34, Color("#030814", 0.56))
		draw_circle(center, 33, Color("#f6d26b", 0.7) if is_player else Color("#ff6e91", 0.7))
		draw_circle(center, 29, Color("#071126", 0.92))
		draw_arc(center, 35, -PI * 0.74, PI * 0.24, 28, trim, 3.0)
		if token != null:
			draw_texture_rect(token, Rect2(center - Vector2(38, 50), Vector2(76, 76)), false)
		else:
			var body: Color = Color("#32d2ff") if is_player else Color("#ff5f7d")
			draw_circle(center + Vector2(0, -5), 24, body)
		var hp_ratio: float = float(unit["hp"]) / float(unit["max_hp"])
		var hp_rect := Rect2(center + Vector2(-31, 34), Vector2(62, 10))
		draw_bar(hp_rect, hp_ratio, Color("#65e08c") if is_player else Color("#ff6685"), "%d/%d" % [unit["hp"], unit["max_hp"]])
		if unit["block"] > 0:
			draw_circle(center + Vector2(28, -28), 14, Color("#8fffd8"))
			draw_string(get_theme_default_font(), center + Vector2(21, -23), str(unit["block"]), HORIZONTAL_ALIGNMENT_CENTER, 16, 12, Color("#10233b"))

func draw_enemy_intents() -> void:
	if phase != "player":
		return
	var hero := get_player()
	if hero.is_empty():
		return
	var hero_pos: Vector2i = hero["pos"]
	for unit in units:
		if unit["team"] != "enemy":
			continue
		var unit_pos: Vector2i = unit["pos"]
		var center: Vector2 = tile_rect(unit_pos).get_center()
		var attacking: bool = manhattan(unit_pos, hero_pos) <= 1
		var label: String = "攻击 %d" % unit["atk"] if attacking else "靠近"
		var intent_color: Color = Color("#ff6685") if attacking else Color("#ffd66e")
		var intent_rect := Rect2(center + Vector2(-31, -62), Vector2(62, 22))
		draw_rect(intent_rect, Color("#071126", 0.78))
		draw_rect(intent_rect, intent_color, false, 1.5)
		draw_string(get_theme_default_font(), intent_rect.position + Vector2(0, 16), label, HORIZONTAL_ALIGNMENT_CENTER, intent_rect.size.x, 12, intent_color)

func draw_effects() -> void:
	for effect in effects:
		var age: float = effect["age"]
		var duration: float = effect["duration"]
		var progress: float = clampf(age / duration, 0.0, 1.0)
		var pos: Vector2 = effect["pos"] + Vector2(0, -34.0 * progress)
		var color: Color = effect["color"]
		color.a = 1.0 - progress
		var text: String = effect["text"]
		draw_string(get_theme_default_font(), pos + Vector2(-44, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 88, 20, color)
		if effect["kind"] == "hit":
			draw_circle(effect["pos"], 18.0 + 24.0 * progress, Color("#ff6685", 0.28 * (1.0 - progress)), false, 3.0)
		elif effect["kind"] == "heal":
			draw_circle(effect["pos"], 16.0 + 20.0 * progress, Color("#8fffd8", 0.28 * (1.0 - progress)), false, 3.0)
		elif effect["kind"] == "guard":
			draw_circle(effect["pos"], 20.0 + 16.0 * progress, Color("#dffdf2", 0.22 * (1.0 - progress)), false, 4.0)

func draw_side_panel(size: Vector2) -> void:
	var panel := Rect2(Vector2(board_rect.end.x + 34, 96), Vector2(size.x - board_rect.end.x - 68, 370))
	draw_panel(panel, Color("#101a32", 0.9), Color("#9fd7ff", 0.28))
	draw_string(get_theme_default_font(), panel.position + Vector2(22, 38), "苍纹牌阵", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 44, 28, Color("#fff4ba"))
	draw_string(get_theme_default_font(), panel.position + Vector2(22, 64), "战术牌组 / 试作战斗", HORIZONTAL_ALIGNMENT_LEFT, panel.size.x - 44, 14, Color("#cfe9ff"))
	var hero := get_player()
	var hero_hp_ratio: float = float(hero["hp"]) / float(hero["max_hp"])
	var portrait_rect := Rect2(panel.position + Vector2(22, 92), Vector2(92, 92))
	draw_panel(portrait_rect, Color("#071126", 0.82), Color("#f6d26b", 0.42))
	var hero_token: Texture2D = token_textures.get("hero")
	if hero_token != null:
		draw_texture_rect(hero_token, portrait_rect.grow(-8), false)
	draw_string(get_theme_default_font(), panel.position + Vector2(132, 112), String(hero["name"]), HORIZONTAL_ALIGNMENT_LEFT, 240, 22, Color.WHITE)
	draw_string(get_theme_default_font(), panel.position + Vector2(132, 138), "力量 +%d    格挡 %d" % [player_power, hero["block"]], HORIZONTAL_ALIGNMENT_LEFT, 260, 16, Color("#ffd6ef"))
	draw_bar(Rect2(panel.position + Vector2(132, 156), Vector2(214, 18)), hero_hp_ratio, Color("#65e08c"), "生命 %d / %d" % [hero["hp"], hero["max_hp"]])

	var energy_x: float = panel.position.x + 374.0
	draw_string(get_theme_default_font(), Vector2(energy_x, panel.position.y + 112), "能量", HORIZONTAL_ALIGNMENT_LEFT, 130, 17, Color("#8fffd8"))
	for i in range(START_ENERGY):
		var pip_center := Vector2(energy_x + 18 + float(i * 34), panel.position.y + 148)
		draw_circle(pip_center, 13, Color("#45f0c1") if i < energy else Color("#31425f"))
		draw_circle(pip_center, 13, Color("#dffdf2", 0.35), false, 2.0)
	draw_string(get_theme_default_font(), Vector2(energy_x, panel.position.y + 178), "%d / %d" % [energy, START_ENERGY], HORIZONTAL_ALIGNMENT_LEFT, 130, 16, Color.WHITE)

	var log_rect := Rect2(panel.position + Vector2(22, 206), Vector2(panel.size.x - 44, 66))
	draw_panel(log_rect, Color("#071126", 0.72), Color("#78d7ff", 0.18))
	draw_string(get_theme_default_font(), log_rect.position + Vector2(14, 25), message, HORIZONTAL_ALIGNMENT_LEFT, log_rect.size.x - 28, 16, Color("#e6f2ff"))
	draw_string(get_theme_default_font(), log_rect.position + Vector2(14, 49), "点击卡牌后，棋盘会显示可用目标。", HORIZONTAL_ALIGNMENT_LEFT, log_rect.size.x - 28, 13, Color("#9fb7d8"))

	var deck_rect := Rect2(panel.position + Vector2(22, 288), Vector2(panel.size.x - 44, 32))
	draw_rect(deck_rect, Color("#071126", 0.55))
	draw_string(get_theme_default_font(), deck_rect.position + Vector2(14, 22), "抽牌堆 %d     弃牌堆 %d     敌人 %d" % [draw_pile.size(), discard_pile.size(), enemies_left()], HORIZONTAL_ALIGNMENT_LEFT, deck_rect.size.x - 28, 15, Color("#cfe9ff"))

	end_turn_rect = Rect2(Vector2(panel.position.x + 22, panel.end.y - 42), Vector2(142, 34))
	var button_color := Color("#f6d26b") if phase == "player" and not victory and not defeat else Color("#59617e")
	draw_button(end_turn_rect, "结束回合", button_color)

	restart_rect = Rect2(Vector2(end_turn_rect.end.x + 12, end_turn_rect.position.y), Vector2(112, 34))
	draw_button(restart_rect, "重开", Color("#6ad7ff"))

func draw_hand(size: Vector2) -> void:
	hand_rects.clear()
	var card_w: int = 166
	var card_h: int = 194
	var gap: int = 12
	var total_w: int = hand.size() * card_w + maxi(0, hand.size() - 1) * gap
	var start_x: float = maxf(42.0, (size.x - float(total_w)) * 0.5)
	var y: float = size.y - float(card_h) - 22.0
	var dock_rect := Rect2(Vector2(0, y - 18), Vector2(size.x, float(card_h) + 40.0))
	draw_rect(dock_rect, Color("#071126", 0.48))
	draw_string(get_theme_default_font(), Vector2(74, y - 30), "手牌", HORIZONTAL_ALIGNMENT_LEFT, 160, 18, Color("#fff4ba"))
	for i in range(hand.size()):
		var rect := Rect2(Vector2(start_x + float(i * (card_w + gap)), y), Vector2(card_w, card_h))
		var c: Dictionary = hand[i]
		var playable: bool = c["cost"] <= energy and phase == "player"
		var fill: Color = Color("#fff7cf") if playable else Color("#8891a9")
		var art_texture: Texture2D = card_textures.get(c["kind"])
		if i == hover_card and playable:
			rect.position.y -= 10.0
		if i == selected_card:
			rect.position.y -= 8.0
		hand_rects.append(rect)
		if i == selected_card:
			draw_rect(rect.grow(7), Color("#79f2c9", 0.88))
		draw_rect(Rect2(rect.position + Vector2(0, 5), rect.size), Color("#030814", 0.32))
		draw_rect(rect, fill)
		draw_rect(rect.grow(-3), Color("#14203d", 0.09))
		draw_rect(rect, Color("#14203d"), false, 2.0)
		if art_texture != null:
			var art_rect := Rect2(rect.position + Vector2(12, 46), Vector2(card_w - 24, 94))
			draw_texture_rect(art_texture, art_rect, false)
			draw_rect(art_rect, Color("#101832", 0.18), false, 1.5)
		draw_circle(rect.position + Vector2(24, 26), 17, Color("#172342"))
		draw_string(get_theme_default_font(), rect.position + Vector2(19, 32), str(c["cost"]), HORIZONTAL_ALIGNMENT_CENTER, 10, 18, Color("#f6d26b"))
		draw_string(get_theme_default_font(), rect.position + Vector2(50, 32), c["title"], HORIZONTAL_ALIGNMENT_LEFT, card_w - 64, 17, Color("#101832"))
		draw_rect(Rect2(rect.position + Vector2(12, 148), Vector2(card_w - 24, 34)), Color("#fff7cf", 0.86))
		draw_string(get_theme_default_font(), rect.position + Vector2(16, 169), c["text"], HORIZONTAL_ALIGNMENT_LEFT, card_w - 32, 13, Color("#24304c"))

func draw_top_bar(size: Vector2) -> void:
	draw_string(get_theme_default_font(), Vector2(74, 42), "第 %d 回合" % turn, HORIZONTAL_ALIGNMENT_LEFT, 180, 22, Color("#fff4ba"))
	draw_string(get_theme_default_font(), Vector2(210, 42), phase_name(), HORIZONTAL_ALIGNMENT_LEFT, 180, 22, Color("#dce6ff"))
	draw_string(get_theme_default_font(), Vector2(size.x - 292, 42), "剩余敌人：%d" % enemies_left(), HORIZONTAL_ALIGNMENT_LEFT, 220, 22, Color("#ffcfda"))

func draw_overlays(size: Vector2) -> void:
	if not victory and not defeat:
		return
	var rect := Rect2(Vector2(size.x * 0.5 - 220, size.y * 0.5 - 80), Vector2(440, 160))
	draw_rect(rect, Color("#101832", 0.94))
	draw_rect(rect, Color("#f6d26b"), false, 3.0)
	var title := "胜利" if victory else "战败"
	var body := "纹章之路已经开启。重开可尝试更漂亮的走位。" if victory else "阿斯特拉倒下了。重开并规划更锋利的回合。"
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 52), title, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 56, 32, Color("#fff4ba"))
	draw_string(get_theme_default_font(), rect.position + Vector2(28, 96), body, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 56, 16, Color.WHITE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		update_hover_card(event.position)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		handle_click(event.position)

func update_hover_card(pos: Vector2) -> void:
	var next_hover := -1
	for i in range(hand_rects.size()):
		if hand_rects[i].has_point(pos):
			next_hover = i
			break
	if next_hover != hover_card:
		hover_card = next_hover
		queue_redraw()

func handle_click(pos: Vector2) -> void:
	if restart_rect.has_point(pos):
		start_run()
		return
	if victory or defeat or phase != "player":
		return
	if end_turn_rect.has_point(pos):
		end_player_turn()
		return
	for i in range(hand_rects.size()):
		if hand_rects[i].has_point(pos):
			select_card(i)
			return
	if board_rect.has_point(pos) and selected_card >= 0:
		var tile := screen_to_tile(pos)
		try_play_card(tile)

func select_card(index: int) -> void:
	if hand[index]["cost"] > energy:
		message = "能量不足，无法使用「%s」。" % hand[index]["title"]
		selected_card = -1
	else:
		selected_card = index
		message = "选择「%s」的目标格。" % hand[index]["title"]
		add_screen_effect(hand_rects[index].get_center(), "选中", Color("#79f2c9"), "guard")
	queue_redraw()

func try_play_card(tile: Vector2i) -> void:
	if selected_card < 0 or selected_card >= hand.size():
		return
	var c: Dictionary = hand[selected_card]
	if not get_valid_tiles().has(tile):
		message = "目标不在范围内。"
		queue_redraw()
		return
	var played := false
	var target = unit_at(tile)
	var hero := get_player()
	match c["kind"]:
		CARD_STRIKE:
			played = target != null and target["team"] == "enemy" and damage_unit(target, 7 + player_power)
		CARD_LANCE:
			played = target != null and target["team"] == "enemy" and damage_unit(target, 9 + player_power)
		CARD_DASH:
			played = move_player(tile)
		CARD_GUARD:
			hero["block"] = hero["block"] + 8
			message = "阿斯特拉获得8点格挡。"
			add_tile_effect(hero["pos"], "+8格挡", Color("#8fffd8"), "guard")
			played = true
		CARD_ENGAGE:
			player_power += 2
			draw_cards(1)
			message = "纹章共鸣：力量提升，并抽1张牌。"
			add_tile_effect(hero["pos"], "力量+2", Color("#f6d26b"), "guard")
			played = true
		CARD_HEAL:
			hero["hp"] = mini(hero["max_hp"], hero["hp"] + 6)
			message = "愈光恢复6点生命。"
			add_tile_effect(hero["pos"], "+6生命", Color("#8fffd8"), "heal")
			played = true
	if played:
		energy -= c["cost"]
		discard_pile.append(c)
		hand.remove_at(selected_card)
		selected_card = -1
		hover_card = -1
		clear_dead_units()
		check_end_state()
	queue_redraw()

func get_valid_tiles() -> Array:
	var tiles: Array = []
	if selected_card < 0 or selected_card >= hand.size():
		return tiles
	var hero := get_player()
	var hero_pos: Vector2i = hero["pos"]
	var c: Dictionary = hand[selected_card]
	match c["kind"]:
		CARD_STRIKE:
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var strike_pos: Vector2i = hero_pos + d
				if in_bounds(strike_pos) and enemy_at(strike_pos) != null:
					tiles.append(strike_pos)
		CARD_LANCE:
			for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				for r in range(1, 4):
					var lance_pos: Vector2i = hero_pos + d * r
					if not in_bounds(lance_pos):
						break
					if unit_at(lance_pos) != null:
						if enemy_at(lance_pos) != null:
							tiles.append(lance_pos)
						break
		CARD_DASH:
			for y in range(GRID_H):
				for x in range(GRID_W):
					var dash_pos := Vector2i(x, y)
					if dash_pos != hero_pos and in_bounds(dash_pos) and unit_at(dash_pos) == null and manhattan(hero_pos, dash_pos) <= 3:
						tiles.append(dash_pos)
		CARD_GUARD, CARD_ENGAGE, CARD_HEAL:
			tiles.append(hero_pos)
	return tiles

func end_player_turn() -> void:
	phase = "enemy"
	selected_card = -1
	for c in hand:
		discard_pile.append(c)
	hand.clear()
	message = "敌方行动。"
	queue_redraw()
	await get_tree().create_timer(0.35).timeout
	enemy_turn()

func enemy_turn() -> void:
	if victory or defeat:
		return
	var hero := get_player()
	var hero_pos: Vector2i = hero["pos"]
	for enemy in units.duplicate():
		if enemy["team"] != "enemy":
			continue
		var enemy_pos: Vector2i = enemy["pos"]
		if manhattan(enemy_pos, hero_pos) <= 1:
			hit_hero(int(enemy["atk"]))
			message = "%s 攻击，造成%d点伤害。" % [enemy["name"], enemy["atk"]]
			add_tile_effect(hero_pos, "-%d" % enemy["atk"], Color("#ff6685"), "hit")
		else:
			step_enemy_toward(enemy, hero_pos)
			message = "%s 正在逼近。" % enemy["name"]
			add_tile_effect(enemy["pos"], "移动", Color("#ffd66e"), "guard")
		queue_redraw()
		await get_tree().create_timer(0.28).timeout
	check_end_state()
	if victory or defeat:
		queue_redraw()
		return
	start_player_turn()

func start_player_turn() -> void:
	turn += 1
	phase = "player"
	energy = START_ENERGY
	var hero := get_player()
	hero["block"] = 0
	draw_cards(HAND_SIZE)
	message = "新手牌。寻找最佳进攻角度。"
	queue_redraw()

func damage_unit(unit: Dictionary, amount: int) -> bool:
	unit["hp"] = unit["hp"] - amount
	message = "%s 受到%d点伤害。" % [unit["name"], amount]
	add_tile_effect(unit["pos"], "-%d" % amount, Color("#ff6685"), "hit")
	return true

func hit_hero(amount: int) -> void:
	var hero := get_player()
	var blocked: int = mini(hero["block"], amount)
	hero["block"] = hero["block"] - blocked
	hero["hp"] = hero["hp"] - (amount - blocked)

func move_player(tile: Vector2i) -> bool:
	var hero := get_player()
	if unit_at(tile) != null:
		return false
	hero["pos"] = tile
	message = "阿斯特拉完成换位。"
	add_tile_effect(tile, "移动", Color("#79f2c9"), "guard")
	return true

func step_enemy_toward(enemy: Dictionary, target: Vector2i) -> void:
	var options: Array = []
	var enemy_pos: Vector2i = enemy["pos"]
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var p: Vector2i = enemy_pos + d
		if in_bounds(p) and unit_at(p) == null:
			options.append(p)
	if options.is_empty():
		return
	options.sort_custom(func(a, b): return manhattan(a, target) < manhattan(b, target))
	enemy["pos"] = options[0]

func clear_dead_units() -> void:
	units = units.filter(func(u): return u["hp"] > 0)

func check_end_state() -> void:
	if units.filter(func(u): return u["team"] == "enemy").is_empty():
		victory = true
		phase = "done"
		message = "胜利。"
	var hero := get_player()
	if hero.is_empty() or hero["hp"] <= 0:
		defeat = true
		phase = "done"
		message = "战败。"

func get_player() -> Dictionary:
	for unit in units:
		if unit["team"] == "player":
			return unit
	return {}

func unit_at(tile: Vector2i) -> Variant:
	for unit in units:
		var unit_pos: Vector2i = unit["pos"]
		if unit_pos == tile:
			return unit
	return null

func enemy_at(tile: Vector2i) -> Variant:
	var unit = unit_at(tile)
	if unit != null and unit["team"] == "enemy":
		return unit
	return null

func enemies_left() -> int:
	return units.filter(func(u): return u["team"] == "enemy").size()

func get_enemy_threat_tiles() -> Array:
	var tiles: Array = []
	for unit in units:
		if unit["team"] != "enemy":
			continue
		var unit_pos: Vector2i = unit["pos"]
		for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var threat_pos: Vector2i = unit_pos + d
			if in_bounds(threat_pos) and not tiles.has(threat_pos):
				tiles.append(threat_pos)
	return tiles

func add_tile_effect(tile: Vector2i, text: String, color: Color, kind: String) -> void:
	add_screen_effect(tile_rect(tile).get_center(), text, color, kind)

func add_screen_effect(pos: Vector2, text: String, color: Color, kind: String) -> void:
	effects.append({
		"pos": pos,
		"text": text,
		"color": color,
		"kind": kind,
		"age": 0.0,
		"duration": 0.78,
	})
	queue_redraw()

func tile_rect(tile: Vector2i) -> Rect2:
	return Rect2(board_rect.position + Vector2(tile.x * TILE, tile.y * TILE), Vector2(TILE, TILE)).grow(-2)

func screen_to_tile(pos: Vector2) -> Vector2i:
	var local: Vector2 = pos - board_rect.position
	return Vector2i(floori(local.x / TILE), floori(local.y / TILE))

func in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < GRID_W and tile.y < GRID_H

func manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
