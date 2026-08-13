class_name BulletBase
extends CharacterBody3D
## 子弹抽象基类：封装所有通用行为。
## - 沿 _direction 飞行，碰到物体沿法线反弹
## - 撞玩家墙：反弹，无特殊效果
## - 撞 z+ 轴目标墙：对其造成伤害并获得固定分数
## - 撞上下左右四面墙：反弹，无特殊效果
## - 子弹 z 低于玩家 z 5 米（漏接飞过）：玩家受伤
## - 子弹出界（z 超出目标墙 10 米 / |y| > 10 米）自动销毁
## 子弹不会超时，可一直存在，除非被销毁。
## 子类通过覆写以下钩子实现各自的伤害增强机制：
## - _on_bounced(hit)：每次碰撞反弹后调用，参数为碰撞到的物体
## - _on_tick(delta)：每物理帧调用

## 飞行速度（单位/秒）
@export var speed: float = 14.0
## 命中目标墙的伤害（初始值由子类决定）
@export var damage: float = 5.0
## 子弹当前分值（固定 10，命中目标墙时获得）
@export var catch_score: int = 10
## 玩家漏接子弹时的扣血量
@export var miss_penalty: float = 10.0
## 子弹 z 低于玩家 z 该值（米）即判定漏接，玩家受伤
@export var hurt_margin: float = 5.0
## 子弹 z 高于目标墙 z 该值（米）即出界自动销毁
@export var despawn_margin: float = 10.0
## 子弹 y 绝对值超过该值（米）即自动销毁
@export var despawn_height: float = 10.0

var _direction: Vector3 = Vector3.FORWARD
var _age: float = 0.0

func _ready() -> void:
	# 加入子弹分组，便于 Boss 死亡时销毁场上所有子弹
	add_to_group("bullet")

## 设置飞行方向（由发射者调用）
func setup(dir: Vector3) -> void:
	_direction = dir.normalized()

func _physics_process(delta: float) -> void:
	var collision := move_and_collide(_direction * speed * delta)
	if collision:
		var hit := collision.get_collider()
		var reflect := true
		if _is_in_group_ancestor(hit, "player"):
			# 撞玩家墙：按玩家格挡状态决定是否反弹
			reflect = _handle_player_hit(hit)
		elif _is_in_group_ancestor(hit, "wall"):
			# 撞 z+ 目标墙：对其造成伤害，并获得分数
			var health_bar := _find_health_bar(hit)
			if health_bar != null:
				health_bar.take_damage(damage)
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null and hud.has_method("add_score"):
				hud.add_score(catch_score)
		# 其余（上下左右四面墙）无特殊效果
		if reflect:
			# 沿碰撞法线反弹，速度大小保持不变
			_direction = _direction.bounce(collision.get_normal())
			# 通知子类：碰撞后伤害增强等
			_on_bounced(hit)
		else:
			# 格挡失败：子弹穿透玩家板子，继续沿原方向飞行
			global_position -= collision.get_normal() * 0.01
	_age += delta
	# 通知子类：每帧更新（如按时间的增强）
	_on_tick(delta)
	# 出生后短暂保护，避免发射瞬间就误判"漏接"
	if _age < 0.15:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null and global_position.z < player.global_position.z - hurt_margin:
		# 子弹漏接飞过玩家（z 方向超 5 米）：玩家受伤
		_on_player_hurt()
		return
	var wall := get_tree().get_first_node_in_group("wall")
	if wall != null and global_position.z > wall.global_position.z + despawn_margin:
		# 飞出 z+ 墙后 10 米：出界自动销毁
		queue_free()
		return
	if absf(global_position.y) > despawn_height:
		# y 绝对值超过 10 米：出界自动销毁
		queue_free()
		return

## 子类钩子：每次碰撞反弹后调用
func _on_bounced(_hit: Node) -> void:
	pass

## 子类钩子：每物理帧调用
func _on_tick(_delta: float) -> void:
	pass

## 玩家漏接子弹而受伤：扣血并销毁子弹
func _on_player_hurt() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var bar := player.get_node_or_null("HealthBar")
		if bar != null and bar.has_method("take_damage"):
			bar.take_damage(miss_penalty)
	queue_free()

## 从碰撞对象向上查找带 HealthBar（可扣血）的目标节点
func _find_health_bar(from: Node) -> Node:
	var node := from
	while node != null:
		var bar := node.get_node_or_null("HealthBar")
		if bar != null and bar.has_method("take_damage"):
			return bar
		node = node.get_parent()
	return null

## 判断 from 自身或父链上是否属于指定分组
func _is_in_group_ancestor(from: Node, group: String) -> bool:
	var node := from
	while node != null:
		if node.is_in_group(group):
			return true
		node = node.get_parent()
	return false

## 撞到玩家墙时的处理：交给玩家的格挡判定，返回是否反弹子弹。
## 玩家未在 parry 或不存在格挡逻辑时一律正常反弹。
func _handle_player_hit(hit: Node) -> bool:
	var node := hit
	while node != null:
		if node.is_in_group("player"):
			return not node.has_method("try_parry_reflect") or node.try_parry_reflect()
		node = node.get_parent()
	return true
