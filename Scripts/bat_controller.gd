extends Node3D

@export var grip_pivot_path: NodePath
@export var swing_pivot_path: NodePath
@export var camera_rig_path: NodePath
@export var body_look_target_path: NodePath
@export var barrel_socket_path: NodePath

@export var mouse_sensitivity_x: float = 0.0030
@export var mouse_sensitivity_y: float = 0.0022

@export var grip_spring: float = 16.0
@export var swing_spring: float = 22.0
@export var damping: float = 0.84

@export var base_mass: float = 1.0
@export var speed_mass: float = 1.2
@export var hold_mass_bonus: float = 2.0
@export var hold_charge_speed: float = 2.5

@export var min_grip_angle: float = -1.25
@export var max_grip_angle: float = 0.85
@export var min_swing_angle: float = -1.10
@export var max_swing_angle: float = 1.10

@export var roll_amount: float = 0.18
@export var roll_spring: float = 12.0
@export var roll_damping: float = 0.86

@export var camera_follow_speed: float = 10.0

@onready var grip_pivot: Node3D = get_node(grip_pivot_path)
@onready var swing_pivot: Node3D = get_node(swing_pivot_path)
@onready var camera_rig: Node3D = get_node(camera_rig_path)
@onready var body_look_target: Node3D = get_node(body_look_target_path)
@onready var barrel_socket: Node3D = get_node(barrel_socket_path)

var target_grip: float = 0.0
var target_swing: float = 0.0

var current_grip: float = 0.0
var current_swing: float = 0.0

var grip_velocity: float = 0.0
var swing_velocity: float = 0.0

var current_roll: float = 0.0
var roll_velocity: float = 0.0

var hold_charge: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		target_swing -= event.relative.x * mouse_sensitivity_x
		target_grip -= event.relative.y * mouse_sensitivity_y

		target_grip = clamp(target_grip, min_grip_angle, max_grip_angle)
		target_swing = clamp(target_swing, min_swing_angle, max_swing_angle)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_update_hold_charge(delta)
	_update_bat_motion(delta)
	_update_camera(delta)


func _update_hold_charge(delta: float) -> void:
	if Input.is_action_pressed("click"):
		hold_charge = min(1.0, hold_charge + delta * hold_charge_speed)
	else:
		hold_charge = max(0.0, hold_charge - delta * hold_charge_speed * 1.5)


func _update_bat_motion(delta: float) -> void:
	var grip_diff: float = target_grip - current_grip
	var swing_diff: float = target_swing - current_swing

	var motion_speed: float = abs(grip_velocity) + abs(swing_velocity)
	var mass_multiplier: float = base_mass + motion_speed * speed_mass + hold_charge * hold_mass_bonus

	grip_velocity += grip_diff * grip_spring * mass_multiplier * delta
	swing_velocity += swing_diff * swing_spring * mass_multiplier * delta

	grip_velocity *= damping
	swing_velocity *= damping

	current_grip += grip_velocity * delta
	current_swing += swing_velocity * delta

	var target_roll: float = -swing_velocity * roll_amount
	var roll_diff: float = target_roll - current_roll

	roll_velocity += roll_diff * roll_spring * delta
	roll_velocity *= roll_damping
	current_roll += roll_velocity * delta

	grip_pivot.rotation.x = current_grip
	swing_pivot.rotation.x = current_swing
	swing_pivot.rotation.z = current_roll


func _update_camera(delta: float) -> void:
	var desired_position: Vector3 = barrel_socket.global_position
	camera_rig.global_position = camera_rig.global_position.lerp(
		desired_position,
		delta * camera_follow_speed
	)

	camera_rig.look_at(body_look_target.global_position, Vector3.UP)
