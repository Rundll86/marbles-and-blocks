extends "res://scripts/bullet.gd"
## 橙色子弹：初始 1 伤害，每次撞击上下左右四面墙时伤害翻倍。

func _init() -> void:
	damage = 1.0

func _on_bounced(hit: Node) -> void:
	if _is_in_group_ancestor(hit, "bounce_wall"):
		damage *= 2.0
