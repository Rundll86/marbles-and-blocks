extends CanvasLayer
## 血条：3 层矩形 back / middle / front，挂在目标节点下自动跟随显示在其上方。
## - back：宽度始终为血条宽度（打底）
## - front：宽度 = 血量百分比 * 血条宽度（当前实际血量）
## - middle：宽度以 1 倍速度 lerpf 到 front（缓动动画，血量变化时平滑过渡）

## 最大血量
@export var max_health: float = 100.0
## 当前血量
@export var current_health: float = 100.0
## 血条宽度（像素）
@export var bar_width: float = 120.0
## 血条高度（像素）
@export var bar_height: float = 12.0
## 血条中心相对目标节点的垂直偏移（世界单位）
@export var height_offset: float = 2.5
## middle 跟随 front 的 lerp 速度（1 倍 = 每秒向目标移动剩余差距的 100%）
@export var lerp_speed: float = 1.0

## 血量归零时发出
signal died

var _back: ColorRect
var _middle: ColorRect
var _front: ColorRect
var _middle_width: float
var _died_emitted: bool = false

func _ready() -> void:
	layer = 50
	var bar_size := Vector2(bar_width, bar_height)
	_back = _make_rect(Color(0.2, 0.2, 0.2), bar_size)
	_middle = _make_rect(Color(1.0, 0.8, 0.2), bar_size)
	_front = _make_rect(Color(0.2, 0.9, 0.3), bar_size)
	_middle_width = _front_width()

func _make_rect(color: Color, size: Vector2) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.size = size
	add_child(rect)
	return rect

func _front_width() -> float:
	return bar_width * clampf(current_health / max_health, 0.0, 1.0)

## 受到伤害，扣减当前血量（最低为 0）
func take_damage(amount: float) -> void:
	current_health = clampf(current_health - amount, 0.0, max_health)
	# 血量归零时只发出一次死亡信号
	if current_health <= 0.0 and not _died_emitted:
		_died_emitted = true
		died.emit()

## 重生：血量回满并重置死亡信号（供 Boss 死亡后重生使用）
func respawn() -> void:
	current_health = max_health
	_died_emitted = false

func _process(delta: float) -> void:
	var target := get_parent() as Node3D
	var camera := get_viewport().get_camera_3d()
	if target == null or camera == null:
		return
	# 目标在相机背后时不显示
	visible = not camera.is_position_behind(target.global_position + Vector3.UP * height_offset)
	if not visible:
		return
	# 血条中心投影到目标上方，左上角为绘制原点
	var screen_pos := camera.unproject_position(target.global_position + Vector3.UP * height_offset)
	var top_left := screen_pos - Vector2(bar_width * 0.5, bar_height * 0.5)
	_back.position = top_left
	_middle.position = top_left
	_front.position = top_left

	# front：当前血量比例对应的宽度
	var front_width := _front_width()
	_front.size.x = front_width
	# middle：以 1 倍速度向 front 宽度缓动
	_middle_width = lerpf(_middle_width, front_width, lerp_speed * delta)
	_middle.size.x = _middle_width
