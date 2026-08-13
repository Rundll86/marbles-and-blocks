extends "res://scripts/bullet.gd"
## 橙色子弹：初始 1 伤害，每次撞击上下左右四面墙时伤害 ×1.25
## （倍率可叠加升级加成）。

func _ready() -> void:
	damage = 1.0 + UpgradeState.orange_base_damage_bonus

func _on_bounced(hit: Node) -> void:
	if _is_in_group_ancestor(hit, "bounce_wall"):
		damage *= 2 + UpgradeState.orange_multiplier_bonus
