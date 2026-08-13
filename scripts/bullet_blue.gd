extends "res://scripts/bullet.gd"
## 蓝色子弹：初始 0 伤害，每飞行 1 秒伤害 +20。
## 实现为每帧 damage += delta * 20（连续累加，帧率无关），
## 每秒伤害可叠加升级加成。

func _ready() -> void:
	damage = 0.0 + UpgradeState.blue_base_damage_bonus

func _on_tick(delta: float) -> void:
	damage += delta * (20.0 + UpgradeState.blue_dps_bonus)
