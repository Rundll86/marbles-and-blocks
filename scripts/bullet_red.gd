extends "res://scripts/bullet.gd"
## 红色子弹：初始 5 伤害，每次撞击玩家墙时伤害 +10（均可叠加升级加成）。

func _ready() -> void:
	damage = 5.0 + UpgradeState.red_base_damage_bonus

func _on_bounced(hit: Node) -> void:
	if _is_in_group_ancestor(hit, "player"):
		damage += 10.0 + UpgradeState.red_hit_bonus
