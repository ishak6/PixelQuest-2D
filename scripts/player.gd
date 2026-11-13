extends CharacterBody2D
class_name PQPlayer

signal died
signal death_animation_finished

const SPEED := 285.0
const JUMP_VELOCITY := -560.0
const GRAVITY := 1450.0

const INK := Color("#172033")
const HAIR := Color("#8b5a3c")
const SKIN := Color("#ffd6a5")
const SHIRT := Color("#243b64")
const SCARF := Color("#e63946")
const GOLD := Color("#ffd166")
const WHITE := Color("#fff8e8")

var controls_enabled := true
var facing := 1
var move_input := 0.0
var jump_requested := false
var touch_control_active := false

# Animation state is derived from actual physics, not input alone.
var animation_time := 0.0
var animation_state := "idle"
var landing_timer := 0.0
var was_on_floor := false
var run_phase := 0.0
var blink_timer := 0.0
var blink_cooldown := 2.4
var jump_flash := 0.0
var dying := false
var death_elapsed := 0.0

func _ready() -> void:
    was_on_floor = is_on_floor()
    blink_cooldown = 2.0 + randf() * 1.8

func _process(delta: float) -> void:
    animation_time += delta
    if dying:
        death_elapsed += delta
        animation_state = "death"
        queue_redraw()
        if death_elapsed >= 0.42:
            dying = false
            death_animation_finished.emit()
        return
    landing_timer = maxf(0.0, landing_timer - delta)
    jump_flash = maxf(0.0, jump_flash - delta)

    if animation_state == "run":
        run_phase += delta * 15.0
    else:
        run_phase += delta * 5.0

    blink_timer += delta
    if blink_timer >= blink_cooldown:
        blink_timer = 0.0
        blink_cooldown = 2.5 + randf() * 2.2

    if landing_timer > 0.0:
        animation_state = "land"
    elif not is_on_floor():
        animation_state = "jump" if velocity.y < 0.0 else "fall"
    elif absf(velocity.x) > 12.0:
        animation_state = "run"
    else:
        animation_state = "idle"

    queue_redraw()

func begin_death() -> void:
    if dying:
        return
    dying = true
    controls_enabled = false
    death_elapsed = 0.0
    animation_state = "death"

func _physics_process(delta: float) -> void:
    if not controls_enabled or dying:
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
        jump_flash = 0.12

    jump_requested = false
    move_and_slide()

    var on_floor_now := is_on_floor()
    if on_floor_now and not was_on_floor and velocity.y >= 0.0:
        landing_timer = 0.16
    was_on_floor = on_floor_now

    for i in get_slide_collision_count():
        var collision := get_slide_collision(i)
        if collision.get_collider().is_in_group("deadly"):
            died.emit()
            return

func _draw() -> void:
    var bob := 0.0
    var leg_swing := 0.0
    var arm_swing := 0.0
    var arm_spread := 0.0
    var tilt := 0.0
    var squash := 0.0
    var leg_lift := 0.0
    var scarf_wave := 0.0

    match animation_state:
        "idle":
            bob = sin(animation_time * 3.0) * 1.0
            scarf_wave = sin(animation_time * 4.0) * 1.0
        "run":
            leg_swing = sin(run_phase) * 5.0
            arm_swing = -leg_swing * 0.8
            bob = absf(sin(run_phase * 2.0)) * -2.0
            tilt = -0.055 * float(facing)
            scarf_wave = sin(run_phase * 1.5) * 3.0
        "jump":
            leg_lift = -4.0
            arm_swing = -5.0
            arm_spread = 2.0
            tilt = -0.08 * float(facing)
            scarf_wave = -3.0
        "fall":
            leg_lift = 2.0
            arm_spread = 7.0
            tilt = 0.08 * float(facing)
            scarf_wave = 4.0
        "land":
            squash = 0.13 * (landing_timer / 0.16)
            bob = 2.0 * (landing_timer / 0.16)
            arm_swing = 2.0
            scarf_wave = 2.0
        "death":
            tilt = 1.15 * float(facing)
            arm_spread = 8.0
            leg_lift = 3.0
            squash = 0.16
            scarf_wave = -7.0

    # Ground shadow compresses while airborne to reinforce jump height.
    var shadow_width := 22.0
    var shadow_alpha := 0.20
    if animation_state == "jump" or animation_state == "fall":
        shadow_width = 15.0
        shadow_alpha = 0.12
    draw_rect(Rect2(-shadow_width * 0.5, 4, shadow_width, 3), Color(INK, shadow_alpha))

    draw_set_transform(Vector2(0.0, bob), tilt, Vector2(1.0 + squash * 0.2, 1.0 - squash))

    # Run dust and landing pixels.
    if animation_state == "run" and int(run_phase * 2.0) % 3 == 0:
        draw_rect(Rect2(-16 - float(facing) * 2.0, 1, 3, 2), Color("#dce8e8", 0.8))
    if animation_state == "land":
        draw_rect(Rect2(-17, 1, 3, 2), Color("#dce8e8", 0.9))
        draw_rect(Rect2(14, 0, 3, 3), Color("#dce8e8", 0.9))
    if jump_flash > 0.0:
        draw_rect(Rect2(-14, -3, 3, 3), GOLD)
        draw_rect(Rect2(12, -6, 3, 3), WHITE)

    # Legs and shoes: alternating strides are readable at small sizes.
    var left_leg_x := -8.0 - leg_swing * 0.55
    var right_leg_x := 2.0 + leg_swing * 0.55
    var left_leg_y := -2.0 + leg_lift + maxf(0.0, leg_swing) * 0.35
    var right_leg_y := -2.0 + leg_lift + maxf(0.0, -leg_swing) * 0.35
    draw_rect(Rect2(left_leg_x, left_leg_y, 7, 8), INK)
    draw_rect(Rect2(right_leg_x, right_leg_y, 7, 8), INK)
    draw_rect(Rect2(left_leg_x - 1, left_leg_y + 5, 9, 4), SCARF)
    draw_rect(Rect2(right_leg_x - 1, right_leg_y + 5, 9, 4), SCARF)
    draw_rect(Rect2(left_leg_x, left_leg_y + 5, 5, 1), Color("#ff8fa3"))
    draw_rect(Rect2(right_leg_x, right_leg_y + 5, 5, 1), Color("#ff8fa3"))

    # Arms behind the body.
    draw_rect(Rect2(-13 - arm_spread, -18 + arm_swing, 5, 12), INK)
    draw_rect(Rect2(8 + arm_spread, -18 - arm_swing, 5, 12), INK)
    draw_rect(Rect2(-12 - arm_spread, -12 + arm_swing, 4, 5), SKIN)
    draw_rect(Rect2(8 + arm_spread, -12 - arm_swing, 4, 5), SKIN)

    # Jacket, belt and chest badge.
    draw_rect(Rect2(-11, -20, 22, 21), INK)
    draw_rect(Rect2(-9, -19, 18, 18), SHIRT)
    draw_rect(Rect2(-9, -5, 18, 4), GOLD)
    draw_rect(Rect2(-2, -15, 5, 5), Color("#b8f2e6"))
    draw_rect(Rect2(-1, -14, 3, 3), WHITE)
    draw_rect(Rect2(-8, -2, 16, 2), Color("#087f8c"))

    # Head, layered hair and ears.
    draw_rect(Rect2(-10, -32, 20, 17), INK)
    draw_rect(Rect2(-8, -30, 16, 14), SKIN)
    draw_rect(Rect2(-10, -33, 20, 7), HAIR)
    draw_rect(Rect2(-8, -34, 6, 3), HAIR)
    draw_rect(Rect2(2, -34, 6, 3), HAIR)
    draw_rect(Rect2(-8, -37, 5, 5), HAIR)
    draw_rect(Rect2(-2, -39, 5, 7), HAIR)
    draw_rect(Rect2(4, -36, 5, 4), HAIR)
    draw_rect(Rect2(-7, -32, 3, 2), Color("#b47a51"))
    draw_rect(Rect2(-11, -27, 3, 5), Color("#f2b98f"))
    draw_rect(Rect2(8, -27, 3, 5), Color("#f2b98f"))

    # Brows, blinking eyes and a tiny expressive mouth.
    var eye_x := 2.0 if facing > 0 else -5.0
    var is_blinking := blink_timer < 0.11 and animation_state == "idle"
    draw_rect(Rect2(eye_x - 1, -25, 5, 1), INK)
    if is_blinking:
        draw_rect(Rect2(eye_x, -23, 3, 1), INK)
    else:
        draw_rect(Rect2(eye_x, -24, 3, 3), INK)
        draw_rect(Rect2(eye_x + (1.0 if facing > 0 else 0.0), -24, 1, 1), WHITE)
    draw_rect(Rect2(eye_x + (1.0 if facing > 0 else -3.0), -18, 3, 1), Color("#b96f69"))
    draw_rect(Rect2(-6 if facing > 0 else 3, -20, 2, 2), Color("#f4a6a0", 0.8))

    # Signature scarf tail flutters opposite to the movement.
    var scarf_tail_x := -8.0 - float(facing) * 2.0
    draw_rect(Rect2(-3, -8, 7, 4), SCARF)
    draw_rect(Rect2(scarf_tail_x - scarf_wave * 0.5, -7 + scarf_wave * 0.25, 7, 3), SCARF)
    draw_rect(Rect2(scarf_tail_x - scarf_wave * 0.5, -7 + scarf_wave * 0.25, 4, 1), Color("#ff8fa3"))

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
