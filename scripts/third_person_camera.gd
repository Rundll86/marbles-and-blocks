extends Camera3D
## 第三人称观察摄像机
## 鼠标移动控制视角（偏航/俯仰），滚轮控制相机与观察点的距离。
## 观察点 = 目标节点全局坐标 + 配置偏移。

## 观察目标节点
@export var target: Node3D

## 观察点偏移（叠加在 target 全局坐标上）
@export var observation_offset: Vector3 = Vector3(0.0, 1.0, 0.0)

## 偏航角（度），绕 Y 轴旋转（初始面向 z+ 方向的墙）
@export_range(-360.0, 360.0, 0.1) var yaw: float = 180.0

## 俯仰角（度），绕 X 轴旋转
@export_range(-89.0, 89.0, 0.1) var pitch: float = -30.0

## 最小俯仰角（度）
@export_range(-89.0, 89.0, 0.1) var min_pitch: float = -89.0

## 最大俯仰角（度）
@export_range(-89.0, 89.0, 0.1) var max_pitch: float = 89.0

## 相机与观察点的当前距离
@export var distance: float = 8.0

## 最近观察距离
@export_range(0.1, 100.0, 0.1) var min_distance: float = 1.0

## 最远观察距离
@export_range(0.1, 1000.0, 0.1) var max_distance: float = 30.0

## 鼠标灵敏度
@export var mouse_sensitivity: float = 0.1

## 滚轮缩放灵敏度
@export var zoom_sensitivity: float = 1.0

func _ready() -> void:
	if target == null:
		push_warning("ThirdPersonCamera: 未设置 target，无法控制相机")
	# 确保本相机为当前渲染相机
	current = true
	# 默认捕获鼠标，以便无限转动视角
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# 鼠标移动控制偏航和俯仰
		yaw -= event.relative.x * mouse_sensitivity
		pitch = clampf(pitch + event.relative.y * mouse_sensitivity, min_pitch, max_pitch)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				# 滚轮上滚：拉近
				distance = clampf(distance - zoom_sensitivity, min_distance, max_distance)
			MOUSE_BUTTON_WHEEL_DOWN:
				# 滚轮下滚：拉远
				distance = clampf(distance + zoom_sensitivity, min_distance, max_distance)
			MOUSE_BUTTON_LEFT:
				# 鼠标处于可见状态时，点击左键重新捕获
				if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Esc 释放鼠标
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	if target == null:
		return
	# 观察点 = 目标全局坐标 + 偏移
	var look_point: Vector3 = target.global_position + observation_offset
	# 球坐标系：由偏航/俯仰/距离反推相机位置
	var rot := Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0))
	global_position = look_point - rot * Vector3(0.0, 0.0, distance)
	look_at(look_point, Vector3.UP)
