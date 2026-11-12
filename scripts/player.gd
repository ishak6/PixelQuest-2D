extends CharacterBody2D
class_name PQPlayer

signal died

const SPEED := 285.0
const JUMP_VELOCITY := -560.0
const GRAVITY := 1450.0

var controls_enabled := true
var facing := 1

func _physics_process(delta: float) -> void:
    if not controls_enabled:
        velocity = Vector2.ZERO
        return

    var direction := Input.get_axis("move_left", "move_right")
    if direction != 0.0:
        facing = sign(direction)
    velocity.x = direction * SPEED

    if not is_on_floor():
        velocity.y += GRAVITY * delta
    elif Input.is_action_just_pressed("jump"):
        velocity.y = JUMP_VELOCITY

    move_and_slide()

    for i in get_slide_collision_count():
        var collision := get_slide_collision(i)
        if collision.get_collider().is_in_group("deadly"):
            died.emit()
            return

func _draw() -> void:
    # Original, deliberately simple pixel-hero silhouette.
    draw_rect(Rect2(-10, -23, 20, 22), Color("#26324a"))
    draw_rect(Rect2(-8, -21, 16, 17), Color("#ffd166"))
    draw_rect(Rect2(-7, -8, 6, 8), Color("#ef476f"))
    draw_rect(Rect2(2, -8, 6, 8), Color("#ef476f"))
    draw_rect(Rect2(1 if facing > 0 else -5, -17, 3, 3), Color("#26324a"))
    draw_rect(Rect2(-9, -1, 7, 5), Color("#26324a"))
    draw_rect(Rect2(2, -1, 7, 5), Color("#26324a"))
