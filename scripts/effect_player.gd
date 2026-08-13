extends Node2D
## 特效抽象播放器（移植自 gold-mirror 的 EffectPlayer，2D 屏幕特效）：
## - shot()：显示并播放动画 / 粒子 / 音效，one_shot 时播完自动销毁
## - spawn() / ai(delta)：子类钩子
## 特效场景约定子节点（effect_base.tscn 已提供）：
##   animator(AnimationPlayer)、texture(Sprite2D)、particles(GPUParticles2D)、sounds(AudioStreamPlayer2D)

## 一次性特效：播完自动销毁
@export var one_shot: bool = false
## 自动播放的动画名（animator 中），为空则不播放
@export var autoplay_animation: StringName = &"spawn"

@onready var animator: AnimationPlayer = $animator
@onready var texture: Sprite2D = $texture
@onready var particles: GPUParticles2D = $particles
@onready var sounds: AudioStreamPlayer2D = $sounds

func _ready() -> void:
	particles.one_shot = one_shot
	particles.emitting = false
	hide()
	spawn()

func _physics_process(delta: float) -> void:
	ai(delta)

## 子类钩子：生成时的额外逻辑
func spawn() -> void:
	pass

## 子类钩子：每帧逻辑
func ai(_delta: float) -> void:
	pass

## 播放特效：显示 + 发射粒子 + 播放动画 / 音效；one_shot 时播完自动销毁
func shot() -> void:
	show()
	particles.emitting = true
	if autoplay_animation != StringName("") and animator.has_animation(autoplay_animation):
		animator.play(autoplay_animation)
	sounds.play()
	if one_shot:
		await _wait_finished()
		queue_free()

func _wait_finished() -> void:
	if animator.is_playing():
		await animator.animation_finished
	if particles.emitting:
		await particles.finished
