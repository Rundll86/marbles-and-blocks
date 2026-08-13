extends CSGBox3D
## 使用输入映射 up/down/left/right 移动节点：
## up/down 移动 Y 坐标，left/right 移动 X 坐标。
## 按下 attack 时朝相机前方发射子弹；同一时刻最多存在一颗子弹，
## 必须等上一颗子弹销毁后才能再发射。
## 按住 parry 进入格挡：板子尺寸翻倍、每秒消耗能量；
## 进入 parry 后 0.5 秒内撞到子弹为完美格挡（必反弹 + 能量回满），
## 超过 0.5 秒为非完美格挡（仅 75% 概率反弹，无特殊效果）。

## 移动速度（单位/秒）
@export var move_speed: float = 6
## 最大能量值
@export var max_energy: float = 100.0
## 按住 parry 每秒消耗的能量
@export var energy_drain_rate: float = 50.0
## 未按住 parry 每秒恢复的能量
@export var energy_regen_rate: float = 50.0
## 完美格挡时间窗口（按住 parry 后该秒数内撞到子弹为完美格挡）
@export var perfect_parry_window: float = 0.5
## 非完美格挡反弹子弹的概率
@export_range(0.0, 1.0) var parry_reflect_chance: float = 0.75
## parry 时板子尺寸放大倍数
@export var parry_scale: float = 2.0

## 当前能量值
var energy: float = 100.0
## 当前是否处于 parry 状态
var is_parrying: bool = false
## 本次按住 parry 的持续时间（秒）
var parry_time: float = 0.0

var _pre_parry_size: Vector3 = Vector3.ZERO
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

	# parry 状态：按住 parry 且能量充足时才生效
	var want_parry := Input.is_action_pressed("parry") and energy > 0.0
	if want_parry and not is_parrying:
		# 刚进入 parry：记录当前尺寸并翻倍，重置格挡计时
		_pre_parry_size = size
		size *= Vector3(parry_scale, parry_scale, 1.0)
		parry_time = 0.0
	if not want_parry and is_parrying:
		# 退出 parry：恢复进入前的尺寸
		size = _pre_parry_size
	is_parrying = want_parry

	# 能量：parry 期间每秒消耗，否则每秒恢复
	if is_parrying:
		energy = maxf(energy - energy_drain_rate * delta, 0.0)
		parry_time += delta
	else:
		energy = minf(energy + energy_regen_rate * delta, max_energy)
		parry_time = 0.0
	var hud := get_tree().get_first_node_in_group("hud")
	if hud != null and hud.has_method("set_energy"):
		hud.set_energy(energy)

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

## 子弹撞到玩家时调用：返回是否反弹子弹。
## 未在 parry：正常反弹；完美格挡（进入 parry 0.5 秒内）：必反弹并恢复全部能量；
## 非完美格挡：仅按概率反弹，无特殊效果。
func try_parry_reflect() -> bool:
	if not is_parrying:
		return true
	if parry_time <= perfect_parry_window:
		# 完美格挡：反弹并恢复所有能量，播放完美格挡特效
		energy = max_energy
		_play_perfect_parry_fx()
		return true
	# 非完美格挡：仅按概率反弹
	return randf() < parry_reflect_chance

## 在玩家板子位置播放完美格挡特效（屏幕空间：投影到玩家所在屏幕位置）
func _play_perfect_parry_fx() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud == null:
		return
	var fx: Node2D = (load("res://effects/perfect_parry.tscn") as PackedScene).instantiate()
	hud.add_child(fx)
	fx.position = camera.unproject_position(global_position)
	if fx.has_method("shot"):
		fx.shot()
