extends CharacterBody2D
class_name PQPlayer

signal died

const SPEED := 285.0
const JUMP_VELOCITY := -560.0
const GRAVITY := 1450.0

var controls_enabled := true
var facing := 1
var move_input := 0.0
var jump_requested := false
var touch_control_active := false

# Procedural pixel animation keeps the hero crisp at every screen size.
var animation_time := 0.0
var animation_state := "idle"

func _process(delta: float) -> void:
    animation_time += delta
    if not is_on_floor():
        animation_state = "jump" if velocity.y < 0.0 else "fall"
    elif absf(velocity.x) > 12.0:
        animation_state = "run"
    else:
        animation_state = "idle"
    queue_redraw()

func _physics_process(delta: float) -> void:
    if not controls_enabled:
        velocity = Vector2.ZERO
        return

    var keyboard_direction := Input.get_axis("move_left", "move_right")
    var direction := move_input if touch_control_active else keyboard_direction
    if direction != 0.0:
        facing = int(signf(direction))
    velocity.x = direction * SPEED

    if not is_on_floor():
        velocity.y += GRAVITY * delta
    elif jump_requested or Input.is_action_just_pressed("jump"):
        velocity.y = JUMP_VELOCITY
    jump_requested = false

    move_and_slide()

    for i in get_slide_collision_count():
        var collision := get_slide_collision(i)
        if collision.get_collider().is_in_group("deadly"):
            died.emit()
            return

func _draw() -> void:
    var bob := 0
    var stride := 0
    var left_leg_y := 0
    var right_leg_y := 0
    var left_arm_y := 0
    var right_arm_y := 0
    var arm_spread := 0

    match animation_state:
        "idle":
            bob = int(round(sin(animation_time * 3.2) * 1.2))
        "run":
            var step := sin(animation_time * 18.0)
            stride = int(round(step * 4.0))
            left_leg_y = int(round(maxf(0.0, step) * 3.0))
            right_leg_y = int(round(maxf(0.0, -step) * 3.0))
            left_arm_y = -stride
            right_arm_y = stride
        "jump":
            bob = -2
            left_leg_y = -3
            right_leg_y = -3
            left_arm_y = -5
            right_arm_y = -5
        "fall":
            bob = 2
            left_leg_y = 2
            right_leg_y = 2
            arm_spread = 5

    # Soft pixel shadow; it stays below the hero during jumps and falls.
    draw_rect(Rect2(-12, 3, 24, 3), Color("#26324a", 0.22))

    # Shoes and legs.
    draw_rect(Rect2(-9 - stride, -2 + left_leg_y + bob, 8, 7), Color("#26324a"))
    draw_rect(Rect2(2 + stride, -2 + right_leg_y + bob, 8, 7), Color("#26324a"))
    draw_rect(Rect2(-10 - stride, 3 + left_leg_y + bob, 9, 3), Color("#ef476f"))
    draw_rect(Rect2(2 + stride, 3 + right_leg_y + bob, 9, 3), Color("#ef476f"))

    # Arms and torso.
    draw_rect(Rect2(-13 - arm_spread, -17 + left_arm_y + bob, 5, 12), Color("#26324a"))
    draw_rect(Rect2(8 + arm_spread, -17 + right_arm_y + bob, 5, 12), Color("#26324a"))
    draw_rect(Rect2(-12 - arm_spread, -12 + left_arm_y + bob, 4, 5), Color("#ffd166"))
    draw_rect(Rect2(8 + arm_spread, -12 + right_arm_y + bob, 4, 5), Color("#ffd166"))
    draw_rect(Rect2(-10, -19 + bob, 20, 19), Color("#26324a"))
    draw_rect(Rect2(-8, -18 + bob, 16, 16), Color("#06a6a6"))
    draw_rect(Rect2(-8, -7 + bob, 16, 4), Color("#ffd166"))

    # Head, hair and face.
    draw_rect(Rect2(-9, -30 + bob, 18, 15), Color("#26324a"))
    draw_rect(Rect2(-8, -29 + bob, 16, 13), Color("#ffd6a5"))
    draw_rect(Rect2(-9, -31 + bob, 18, 6), Color("#26324a"))
    draw_rect(Rect2(-10 if facing > 0 else 6, -27 + bob, 4, 5), Color("#26324a"))
    var eye_x := 2 if facing > 0 else -5
    var blink := fposmod(animation_time, 3.7) > 3.58 and animation_state == "idle"
    if blink:
        draw_rect(Rect2(eye_x, -23 + bob, 3, 1), Color("#26324a"))
    else:
        draw_rect(Rect2(eye_x, -24 + bob, 3, 3), Color("#26324a"))
    draw_rect(Rect2(eye_x + (1 if facing > 0 else -1), -24 + bob, 1, 1), Color.WHITE)

    # Small signature scarf pixel.
    draw_rect(Rect2(-2, -8 + bob, 5, 3), Color("#ef476f"))
