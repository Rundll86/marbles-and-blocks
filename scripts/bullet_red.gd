extends "res://scripts/bullet.gd"
## 红色子弹：初始 5 伤害，每次撞击玩家墙时伤害 +10。

func _on_bounced(hit: Node) -> void:
	if _is_in_group_ancestor(hit, "player"):
		damage += 10.0
