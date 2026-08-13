extends CanvasLayer
## 屏幕固定 HUD：
## - 左上角常驻显示分数（Score）和经验值（EXP）
## - 玩家死亡时屏幕中央显示大红字 "DIE"
## - Boss 死亡时玩家获得经验值

## 死亡提示文字
@export var die_text: String = "DIE"
## Boss 死亡奖励经验值
@export var exp_gain: int = 100

var score: int = 0
var experience: int = 0

var _score_label: Label
var _exp_label: Label
var _die_label: Label

func _ready() -> void:
	layer = 100
	_build_ui()
	# 玩家血条归零：显示死亡提示
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var bar := player.get_node_or_null("HealthBar")
		if bar != null:
			bar.died.connect(_on_player_died)
	# Boss 血条归零：获得经验值
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

## Boss 死亡：玩家获得经验值
func _on_boss_died() -> void:
	add_exp(exp_gain)
