extends "res://scripts/bullet.gd"
## 蓝色子弹：初始 5 伤害，每飞行 1 秒伤害 +20。

var _time_accum: float = 0.0

func _on_tick(delta: float) -> void:
	_time_accum += delta
	while _time_accum >= 1.0:
		_time_accum -= 1.0
		damage += 20.0
