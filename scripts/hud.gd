extends CanvasLayer
## 屏幕固定 HUD：
## - 左上角常驻显示分数（Score）和经验值（EXP）
## - 玩家死亡时屏幕中央显示大红字 "DIE"
## - Boss 死亡时玩家获得经验值，Boss 重生（血量 +1000）、销毁场上子弹，
##   并弹出 3 张升级卡片，选择前禁止发射子弹

## 死亡提示文字
@export var die_text: String = "DIE"
## Boss 死亡奖励经验值
@export var exp_gain: int = 100
## Boss 重生时血量增量
@export var boss_hp_increase: float = 1000.0

## 升级卡片池：随机抽取 3 张供玩家选择
const UPGRADE_POOL: Array[Dictionary] = [
	{"id": "red_base", "title": "红球初始伤害 +6"},
	{"id": "red_hit", "title": "红球撞击增加伤害 +8"},
	{"id": "orange_base", "title": "橙球初始伤害 +1"},
	{"id": "orange_mult", "title": "橙球反弹倍率 +0.3"},
	{"id": "blue_base", "title": "蓝球初始伤害 +1"},
	{"id": "blue_dps", "title": "蓝球每秒伤害 +16"},
	{"id": "heal", "title": "恢复 15 点血量"},
	{"id": "move_speed", "title": "移动速度 +1"},
	{"id": "board_width", "title": "弹板宽度 +0.25"},
	{"id": "board_height", "title": "弹板高度 +0.25"},
]

var score: int = 0
var experience: int = 0

var _score_label: Label
var _exp_label: Label
var _die_label: Label
var _upgrade_root: VBoxContainer
var _upgrade_buttons: Array[Button] = []
var _upgrade_picks: Array[Dictionary] = []

func _ready() -> void:
	layer = 100
	_build_ui()
	# 玩家血条归零：显示死亡提示
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var bar := player.get_node_or_null("HealthBar")
		if bar != null:
			bar.died.connect(_on_player_died)
	# Boss 血条归零：获得经验值、重生、弹升级卡片
	var boss := get_tree().get_first_node_in_group("wall")
	if boss != null:
		var bar := boss.get_node_or_null("HealthBar")
		if bar != null:
			bar.died.connect(_on_boss_died)

func _build_ui() -> void:
	_score_label = _make_label("Score: 0", Vector2(20, 10), 32)
	_exp_label = _make_label("EXP: 0", Vector2(20, 50), 32)
	# 死亡提示：全屏居中的大红字，默认隐藏
	_die_label = Label.new()
	_die_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_die_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_die_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_die_label.add_theme_font_size_override("font_size", 160)
	_die_label.add_theme_color_override("font_color", Color(1, 0, 0))
	_die_label.visible = false
	add_child(_die_label)
	# 升级卡片：屏幕中央竖向排列 3 个按钮，默认隐藏
	_upgrade_root = VBoxContainer.new()
	_upgrade_root.set_anchors_preset(Control.PRESET_CENTER)
	_upgrade_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_upgrade_root.add_theme_constant_override("separation", 16)
	_upgrade_root.visible = false
	add_child(_upgrade_root)
	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(320, 64)
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(_on_upgrade_pressed.bind(i))
		_upgrade_root.add_child(btn)
		_upgrade_buttons.append(btn)

func _make_label(text: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
	return label

## 增加分数并刷新显示
func add_score(amount: int) -> void:
	score += amount
	_score_label.text = "Score: %d" % score

## 增加经验值并刷新显示
func add_exp(amount: int) -> void:
	experience += amount
	_exp_label.text = "EXP: %d" % experience

## 玩家死亡：显示大红字提示
func _on_player_died() -> void:
	_die_label.text = die_text
	_die_label.visible = true

## Boss 死亡：获得经验值、重生、销毁子弹、弹出升级卡片
func _on_boss_died() -> void:
	add_exp(exp_gain)
	# 销毁场上所有子弹
	for bullet in get_tree().get_nodes_in_group("bullet"):
		bullet.queue_free()
	# Boss 重生：血量 +1000 并回满
	var boss := get_tree().get_first_node_in_group("wall")
	if boss != null:
		var bar := boss.get_node_or_null("HealthBar")
		if bar != null:
			bar.max_health += boss_hp_increase
			bar.respawn()
	# 弹出 3 张升级卡片，选择前禁止发射子弹
	UpgradeState.upgrading = true
	_show_upgrade_cards()
	# 释放鼠标，便于点击卡片
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## 从升级池随机抽 3 张不重复的卡片显示
func _show_upgrade_cards() -> void:
	var pool := UPGRADE_POOL.duplicate()
	pool.shuffle()
	_upgrade_picks = pool.slice(0, 3)
	for i in _upgrade_buttons.size():
		_upgrade_buttons[i].text = _upgrade_picks[i].title
	_upgrade_root.visible = true

func _on_upgrade_pressed(index: int) -> void:
	_apply_upgrade(_upgrade_picks[index].id)
	_upgrade_root.visible = false
	# 选择完成，恢复发射并重新捕获鼠标
	UpgradeState.upgrading = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

## 将升级加成累加到全局状态
func _apply_upgrade(id: String) -> void:
	match id:
		"red_base":
			UpgradeState.red_base_damage_bonus += 6
		"red_hit":
			UpgradeState.red_hit_bonus += 8
		"orange_base":
			UpgradeState.orange_base_damage_bonus += 1.0
		"orange_mult":
			UpgradeState.orange_multiplier_bonus += 0.3
		"blue_base":
			UpgradeState.blue_base_damage_bonus += 1.0
		"blue_dps":
			UpgradeState.blue_dps_bonus += 16.0
		"heal":
			_heal_player(15.0)
		"move_speed":
			_increase_move_speed(1.0)
		"board_width":
			_resize_player_board(Vector2(0.25, 0.0))
		"board_height":
			_resize_player_board(Vector2(0.0, 0.25))

## 恢复玩家血量
func _heal_player(amount: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var bar := player.get_node_or_null("HealthBar")
		if bar != null and bar.has_method("take_damage"):
			bar.take_damage(-amount)

## 增加玩家移动速度
func _increase_move_speed(amount: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.move_speed += amount

## 改变玩家板子的宽高
func _resize_player_board(delta_size: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player is CSGBox3D:
		player.size.x += delta_size.x
		player.size.y += delta_size.y
