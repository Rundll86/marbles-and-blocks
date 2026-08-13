extends Node3D
## 使用输入映射 up/down/left/right 移动节点：
## up/down 移动 Y 坐标，left/right 移动 X 坐标。
## 按下 attack 时朝相机前方发射子弹；同一时刻最多存在一颗子弹，
## 必须等上一颗子弹销毁后才能再发射。

## 移动速度（单位/秒）
@export var move_speed: float = 9
## 三种子弹场景（红/橙/蓝），每次发射随机其一
const BULLET_SCENES: Array[PackedScene] = [
	preload("res://bullet_red.tscn"),
	preload("res://bullet_orange.tscn"),
	preload("res://bullet_blue.tscn"),
]
## 子弹初速（单位/秒）
@export var bullet_speed: float = 14.0
## 子弹出生点离玩家中心距离（避免与自身重叠）
@export var muzzle_offset: float = 1.0

var _active_bullet: Node3D = null

func _process(delta: float) -> void:
	# get_vector 返回 (x, y)：left/right 影响 x，up/down 影响 y
	# 注意：Godot 中 up 为 -1、down 为 +1，因此 y 方向取反，使 up 对应 Y 轴正方向
	var input := Input.get_vector("left", "right", "up", "down")
	position.x -= input.x * move_speed * delta
	position.y -= input.y * move_speed * delta

	# 单发限制：上一颗子弹未销毁前不能发射；升级选择期间禁止发射
	if Input.is_action_pressed("attack") and not _has_active_bullet() and not UpgradeState.upgrading:
		_spawn_bullet()

func _has_active_bullet() -> bool:
	return _active_bullet != null and is_instance_valid(_active_bullet)

func _spawn_bullet() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	# 随机选择一种子弹：红色 / 橙色 / 蓝色
	var bullet: Node3D = BULLET_SCENES.pick_random().instantiate()
	get_tree().current_scene.add_child(bullet)
	# 发射方向 = 相机前方（屏幕中心朝向）
	var dir := -camera.global_transform.basis.z
	bullet.global_position = global_position + dir * muzzle_offset
	bullet.speed = bullet_speed
	bullet.setup(dir)
	_active_bullet = bullet
