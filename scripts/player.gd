extends CharacterBody2D
class_name PQPlayer

signal died
signal death_animation_finished

const SPEED := 285.0
const JUMP_VELOCITY := -560.0
const GRAVITY := 1450.0

const INK := Color("#172033")
const HAIR := Color("#8b5a3c")
const HAIR_LIGHT := Color("#b47a51")
const SKIN := Color("#ffd6a5")
const SHIRT := Color("#243b64")
const SHIRT_LIGHT := Color("#3f6190")
const SCARF := Color("#e63946")
const SCARF_LIGHT := Color("#ff8fa3")
const GOLD := Color("#ffd166")
const WHITE := Color("#fff8e8")

var controls_enabled := true
var facing := 1
var move_input := 0.0
var jump_requested := false
var touch_control_active := false

var animation_time := 0.0
var animation_state := "idle"
var previous_animation_state := "idle"
var state_time := 0.0
var landing_timer := 0.0
var was_on_floor := false
var run_phase := 0.0
var blink_timer := 0.0
var blink_cooldown := 2.4
var jump_flash := 0.0
var death_elapsed := 0.0
var dying := false
var death_signal_sent := false
var landing_burst := 0.0

func _ready() -> void:
    was_on_floor = is_on_floor()
    blink_cooldown = 1.8 + randf() * 2.0
    queue_redraw()

func _set_animation(next_state: String) -> void:
    if next_state == animation_state:
        return
    previous_animation_state = animation_state
    animation_state = next_state
    state_time = 0.0

func _process(delta: float) -> void:
    animation_time += delta
    state_time += delta
    blink_timer += delta
    if blink_timer >= blink_cooldown:
        blink_timer = 0.0
        blink_cooldown = 2.2 + randf() * 2.5

    jump_flash = maxf(0.0, jump_flash - delta)
    landing_timer = maxf(0.0, landing_timer - delta)
    landing_burst = maxf(0.0, landing_burst - delta)

    if dying:
        death_elapsed += delta
        _set_animation("death")
        queue_redraw()
        if death_elapsed >= 0.78 and not death_signal_sent:
            death_signal_sent = true
            death_animation_finished.emit()
        return

    if landing_timer > 0.0:
        _set_animation("land")
    elif not is_on_floor():
        if velocity.y < -80.0:
            _set_animation("jump")
        elif velocity.y <= 70.0 and velocity.y >= -80.0:
            _set_animation("jump")
        else:
            _set_animation("fall")
    elif absf(velocity.x) > 12.0:
        _set_animation("run")
    else:
        _set_animation("idle")

    if animation_state == "run":
        run_phase += delta * 15.5
    else:
        run_phase += delta * 5.0

    queue_redraw()

func begin_death() -> void:
    if dying:
        return
    dying = true
    controls_enabled = false
    death_elapsed = 0.0
    death_signal_sent = false
    _set_animation("death")
    queue_redraw()

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
        jump_flash = 0.16

    jump_requested = false
    move_and_slide()

    var on_floor_now := is_on_floor()
    if on_floor_now and not was_on_floor and velocity.y >= 0.0:
        landing_timer = 0.22
        landing_burst = 0.18
    was_on_floor = on_floor_now

    for i in get_slide_collision_count():
        var collision := get_slide_collision(i)
        if collision.get_collider().is_in_group("deadly"):
            died.emit()
            return

func _draw() -> void:
    var bob := 0.0
    var body_tilt := 0.0
    var body_squash := 0.0
    var body_stretch := 0.0
    var leg_left_x := -7.0
    var leg_right_x := 2.0
    var leg_left_y := -2.0
    var leg_right_y := -2.0
    var arm_left_angle := 0.0
    var arm_right_angle := 0.0
    var arm_spread := 0.0
    var scarf_wave := 0.0
    var scarf_lift := 0.0
    var head_offset := Vector2.ZERO
    var feet_spread := 0.0

    match animation_state:
        "idle":
            bob = sin(animation_time * 3.0) * 1.2
            body_squash = sin(animation_time * 3.0) * 0.018
            scarf_wave = sin(animation_time * 4.2) * 1.8
            head_offset.y = sin(animation_time * 3.0 + 0.6) * 0.5
        "run":
            var stride := sin(run_phase)
            var counter_stride := sin(run_phase + PI)
            leg_left_x = -7.0 + stride * 4.5
            leg_right_x = 2.0 + counter_stride * 4.5
            leg_left_y = -2.0 - maxf(0.0, counter_stride) * 2.0
            leg_right_y = -2.0 - maxf(0.0, stride) * 2.0
            arm_left_angle = -stride * 0.45
            arm_right_angle = stride * 0.45
            bob = -absf(sin(run_phase * 2.0)) * 2.4
            body_tilt = -0.07 * float(facing)
            scarf_wave = sin(run_phase * 1.4) * 4.0
            scarf_lift = -1.0
        "jump":
            var jump_progress := clampf(state_time / 0.22, 0.0, 1.0)
            body_stretch = 0.10 * (1.0 - jump_progress)
            body_squash = 0.035 * jump_progress
            leg_left_y = 1.0
            leg_right_y = -3.0
            leg_left_x = -9.0
            leg_right_x = 4.0
            arm_left_angle = -0.8
            arm_right_angle = 0.8
            arm_spread = 2.0
            body_tilt = -0.10 * float(facing)
            scarf_wave = -4.0
            scarf_lift = -2.0
        "fall":
            leg_left_y = 0.0
            leg_right_y = 0.0
            leg_left_x = -10.0
            leg_right_x = 5.0
            arm_left_angle = -1.0
            arm_right_angle = 1.0
            arm_spread = 5.0
            body_tilt = 0.12 * float(facing)
            scarf_wave = 5.0
            scarf_lift = 3.0
        "land":
            var impact := clampf(landing_timer / 0.22, 0.0, 1.0)
            body_squash = 0.22 * impact
            body_stretch = -0.05 * (1.0 - impact)
            bob = 2.0 * impact
            leg_left_y = -1.0
            leg_right_y = -1.0
            arm_left_angle = -0.25 * impact
            arm_right_angle = 0.25 * impact
            scarf_wave = 3.0 * impact
        "death":
            var death_phase := death_elapsed
            if death_phase < 0.18:
                body_tilt = 0.18 * float(facing)
                body_squash = 0.12
                arm_spread = 7.0
            elif death_phase < 0.42:
                body_tilt = lerpf(0.18, 1.35 * float(facing), (death_phase - 0.18) / 0.24)
                leg_left_y = -5.0
                leg_right_y = 2.0
                arm_spread = 10.0
                scarf_wave = -8.0
            else:
                body_tilt = 1.35 * float(facing)
                body_squash = 0.24
                leg_left_y = 3.0
                leg_right_y = 3.0
                arm_spread = 8.0
                scarf_wave = -5.0

    var shadow_width := 23.0
    var shadow_alpha := 0.20
    if animation_state == "jump" or animation_state == "fall":
        shadow_width = 14.0
        shadow_alpha = 0.10
    if animation_state == "death":
        shadow_width = 19.0
        shadow_alpha = 0.12
    draw_rect(Rect2(-shadow_width * 0.5, 4, shadow_width, 3), Color(INK, shadow_alpha))

    var scale_y := 1.0 - body_squash + body_stretch
    var scale_x := 1.0 + body_squash * 0.55 - body_stretch * 0.35
    draw_set_transform(Vector2(0.0, bob), body_tilt, Vector2(scale_x, scale_y))

    # Landing burst particles and running dust.
    if animation_state == "run" and int(run_phase * 2.0) % 3 == 0:
        draw_rect(Rect2(-17.0 - float(facing) * 2.0, 0, 3, 2), Color("#dce8e8", 0.85))
        draw_rect(Rect2(-13.0 - float(facing) * 2.0, 2, 2, 2), Color("#ffffff", 0.65))
    if landing_burst > 0.0:
        var particle_spread := (0.18 - landing_burst) * 55.0
        draw_rect(Rect2(-15.0 - particle_spread, -1, 3, 3), Color("#fff1c1", landing_burst / 0.18))
        draw_rect(Rect2(12.0 + particle_spread, -2, 3, 3), Color("#fff1c1", landing_burst / 0.18))
    if jump_flash > 0.0:
        draw_rect(Rect2(-15, -5, 3, 3), GOLD)
        draw_rect(Rect2(12, -8, 3, 3), WHITE)

    # Legs and boots.
    draw_rect(Rect2(leg_left_x, leg_left_y, 7, 9), INK)
    draw_rect(Rect2(leg_right_x, leg_right_y, 7, 9), INK)
    draw_rect(Rect2(leg_left_x - 1, leg_left_y + 5, 9, 4), Color("#26324a"))
    draw_rect(Rect2(leg_right_x - 1, leg_right_y + 5, 9, 4), Color("#26324a"))
    draw_rect(Rect2(leg_left_x - 1, leg_left_y + 7, 9, 2), GOLD)
    draw_rect(Rect2(leg_right_x - 1, leg_right_y + 7, 9, 2), GOLD)

    # Arms are drawn behind the torso; rotation makes their swing clear.
    draw_set_transform(Vector2(-10.0 - arm_spread, -17.0 + bob), body_tilt + arm_left_angle, Vector2.ONE)
    draw_rect(Rect2(-2, -1, 6, 13), INK)
    draw_rect(Rect2(-1, 0, 4, 10), SHIRT_LIGHT)
    draw_rect(Rect2(-1, 9, 5, 5), SKIN)
    draw_set_transform(Vector2(10.0 + arm_spread, -17.0 + bob), body_tilt + arm_right_angle, Vector2.ONE)
    draw_rect(Rect2(-3, -1, 6, 13), INK)
    draw_rect(Rect2(-2, 0, 4, 10), SHIRT_LIGHT)
    draw_rect(Rect2(-3, 9, 5, 5), SKIN)

    draw_set_transform(Vector2(0.0, bob), body_tilt, Vector2(scale_x, scale_y))

    # Jacket, belt, seams and chest emblem.
    draw_rect(Rect2(-11, -21, 22, 22), INK)
    draw_rect(Rect2(-9, -20, 18, 19), SHIRT)
    draw_rect(Rect2(-8, -19, 3, 15), SHIRT_LIGHT)
    draw_rect(Rect2(5, -19, 2, 15), Color("#172f52"))
    draw_rect(Rect2(-9, -5, 18, 4), GOLD)
    draw_rect(Rect2(-2, -15, 5, 5), Color("#b8f2e6"))
    draw_rect(Rect2(-1, -14, 3, 3), WHITE)
    draw_rect(Rect2(-8, -2, 16, 2), Color("#087f8c"))

    # Neck and face.
    draw_rect(Rect2(-4, -25, 8, 7), SKIN)
    draw_rect(Rect2(-10, -34, 20, 19), INK)
    draw_rect(Rect2(-8, -32, 16, 15), SKIN)
    draw_rect(Rect2(-10, -33, 20, 7), HAIR)
    draw_rect(Rect2(-8, -34, 6, 3), HAIR)
    draw_rect(Rect2(2, -34, 6, 3), HAIR)
    draw_rect(Rect2(-8, -37, 5, 5), HAIR)
    draw_rect(Rect2(-2, -39, 5, 7), HAIR)
    draw_rect(Rect2(4, -36, 5, 4), HAIR)
    draw_rect(Rect2(-7, -32, 3, 2), HAIR_LIGHT)
    draw_rect(Rect2(-11, -27, 3, 5), Color("#f2b98f"))
    draw_rect(Rect2(8, -27, 3, 5), Color("#f2b98f"))

    # Eyes, eyebrows and expression change during the death reaction.
    var eye_x := 2.0 if facing > 0 else -5.0
    var is_blinking := blink_timer < 0.12 and animation_state == "idle"
    var eyes_closed := animation_state == "death" and death_elapsed > 0.42
    draw_rect(Rect2(eye_x - 1, -26, 5, 1), INK)
    if is_blinking or eyes_closed:
        draw_rect(Rect2(eye_x, -23, 3, 1), INK)
    else:
        draw_rect(Rect2(eye_x, -25, 3, 3), INK)
        draw_rect(Rect2(eye_x + (1.0 if facing > 0 else 0.0), -25, 1, 1), WHITE)
    if animation_state == "death":
        draw_rect(Rect2(eye_x - 1, -18, 5, 2), INK)
    else:
        draw_rect(Rect2(eye_x + (1.0 if facing > 0 else -3.0), -18, 3, 1), Color("#b96f69"))
    draw_rect(Rect2(-6 if facing > 0 else 3, -20, 2, 2), Color("#f4a6a0", 0.8))

    # Signature scarf: its tail reacts to movement and airtime.
    draw_rect(Rect2(-3, -9, 7, 5), SCARF)
    var scarf_tail_x := -8.0 - float(facing) * 2.0
    draw_rect(Rect2(scarf_tail_x - scarf_wave * 0.5, -8.0 - scarf_lift + scarf_wave * 0.25, 8, 3), SCARF)
    draw_rect(Rect2(scarf_tail_x - scarf_wave * 0.5, -8.0 - scarf_lift + scarf_wave * 0.25, 5, 1), SCARF_LIGHT)

    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
