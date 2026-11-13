extends Node2D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const WORLD_W := 960.0
const FLOOR_Y := 470.0

var player: PQPlayer
var deaths := 0
var level_started := false
var collapsed := false
var collapse_timer := 0.0
var moving_platform: StaticBody2D
var crumble_platform: StaticBody2D
var crumble_visual: ColorRect
var moving_direction := 1.0
var moving_start_x := 520.0
var moving_end_x := 690.0
var ui_layer: CanvasLayer
var death_label: Label
var message_label: Label
var left_held := false
var right_held := false
var jump_held := false
var audio_player: AudioStreamPlayer
var control_buttons: Dictionary = {}
var control_positions: Dictionary = {}
var control_sizes: Dictionary = {}
var control_edit_mode := false
var selected_control := ""
var dragging_control := ""
var drag_offset := Vector2.ZERO
var control_config := ConfigFile.new()
var touch_points: Dictionary = {}

func _ready() -> void:
    _setup_input()
    _build_level()
    _build_ui()
    _spawn_player()
    _show_message("THE FAKE BEGINNING  •  Reach the door. Trust nothing.", 3.5)

func _process(delta: float) -> void:
    if Input.is_action_just_pressed("restart"):
        _restart_level()
    if collapsed:
        collapse_timer -= delta
        if collapse_timer <= 0.0:
            collapsed = false
            _restart_level()
    if is_instance_valid(moving_platform):
        moving_platform.position.x += moving_direction * 95.0 * delta
        if moving_platform.position.x > moving_end_x:
            moving_direction = -1.0
        elif moving_platform.position.x < moving_start_x:
            moving_direction = 1.0

func _physics_process(_delta: float) -> void:
    if not is_instance_valid(player):
        return
    player.move_input = float(right_held) - float(left_held)
    player.touch_control_active = left_held or right_held or jump_held
    if player.global_position.y > 650:
        _player_died()
    if player.global_position.x > 910 and player.global_position.y < 460:
        _win_level()

func _input(event: InputEvent) -> void:
    # Track each finger independently for simultaneous Android touch controls.
    if event is InputEventScreenTouch:
        if event.pressed:
            touch_points[event.index] = event.position
        else:
            touch_points.erase(event.index)
        _refresh_touch_controls()
    elif event is InputEventScreenDrag and touch_points.has(event.index):
        touch_points[event.index] = event.position
        _refresh_touch_controls()

func _refresh_touch_controls() -> void:
    var active_actions := {"move_left": false, "move_right": false, "jump": false}
    for point in touch_points.values():
        for action in control_buttons:
            var button: Button = control_buttons[action]
            if button.get_global_rect().has_point(point):
                active_actions[action] = true
    var any_control_active: bool = active_actions["move_left"] or active_actions["move_right"] or active_actions["jump"]
    if control_edit_mode:
        any_control_active = false
    left_held = active_actions["move_left"] and not control_edit_mode
    right_held = active_actions["move_right"] and not control_edit_mode
    var next_jump: bool = active_actions["jump"] and not control_edit_mode
    if next_jump and not jump_held and is_instance_valid(player):
        player.jump_requested = true
    jump_held = next_jump
    if is_instance_valid(player):
        player.touch_control_active = any_control_active

func _setup_input() -> void:
    for action in ["move_left", "move_right", "jump", "restart"]:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
    _bind_key("move_left", KEY_A)
    _bind_key("move_left", KEY_LEFT)
    _bind_key("move_right", KEY_D)
    _bind_key("move_right", KEY_RIGHT)
    _bind_key("jump", KEY_SPACE)
    _bind_key("jump", KEY_W)
    _bind_key("jump", KEY_UP)
    _bind_key("restart", KEY_R)

func _bind_key(action: String, key: Key) -> void:
    var event := InputEventKey.new()
    event.physical_keycode = key
    if not InputMap.action_has_event(action, event):
        InputMap.action_add_event(action, event)

func _build_level() -> void:
    # Background and decorative clouds.
    var bg := ColorRect.new()
    bg.color = Color("#91d7ef")
    bg.size = Vector2(WORLD_W, 540)
    bg.z_index = -20
    add_child(bg)
    _draw_cloud(Vector2(170, 95))
    _draw_cloud(Vector2(650, 125))
    _draw_cloud(Vector2(835, 75))

    _platform(Vector2(0, FLOOR_Y), Vector2(245, 70), Color("#6dbb58"))
    _platform(Vector2(310, FLOOR_Y), Vector2(115, 70), Color("#6dbb58"))
    _platform(Vector2(470, FLOOR_Y - 80), Vector2(105, 18), Color("#6dbb58"))
    moving_platform = _platform(Vector2(moving_start_x, FLOOR_Y - 5), Vector2(100, 18), Color("#f4a261"))
    _platform(Vector2(770, FLOOR_Y), Vector2(190, 70), Color("#6dbb58"))

    # A suspiciously safe-looking floor tile collapses after contact.
    crumble_platform = StaticBody2D.new()
    crumble_platform.position = Vector2(275, FLOOR_Y - 6)
    var crumble_shape := CollisionShape2D.new()
    var crumble_rect := RectangleShape2D.new()
    crumble_rect.size = Vector2(24, 12)
    crumble_shape.shape = crumble_rect
    crumble_platform.add_child(crumble_shape)
    add_child(crumble_platform)

    var crumble := Area2D.new()
    crumble.position = Vector2(275, FLOOR_Y - 8)
    crumble.add_to_group("crumble")
    var cshape := CollisionShape2D.new()
    var crect := RectangleShape2D.new()
    crect.size = Vector2(24, 12)
    cshape.shape = crect
    crumble.add_child(cshape)
    crumble.body_entered.connect(_on_crumble_touched)
    add_child(crumble)
    crumble_visual = ColorRect.new()
    crumble_visual.position = Vector2(263, FLOOR_Y - 14)
    crumble_visual.size = Vector2(24, 7)
    crumble_visual.color = Color("#b5df76")
    add_child(crumble_visual)

    _spikes(Vector2(360, FLOOR_Y - 16), 54)
    _spikes(Vector2(700, FLOOR_Y - 16), 48)

    var exit_sign := Label.new()
    exit_sign.text = "EXIT"
    exit_sign.position = Vector2(866, FLOOR_Y - 100)
    exit_sign.add_theme_font_size_override("font_size", 25)
    exit_sign.add_theme_color_override("font_color", Color("#ffffff"))
    add_child(exit_sign)
    var door := ColorRect.new()
    door.position = Vector2(875, FLOOR_Y - 72)
    door.size = Vector2(42, 72)
    door.color = Color("#7656a8")
    add_child(door)
    var knob := ColorRect.new()
    knob.position = Vector2(906, FLOOR_Y - 36)
    knob.size = Vector2(4, 4)
    knob.color = Color("#ffd166")
    add_child(knob)

    var finish := Area2D.new()
    finish.position = Vector2(895, FLOOR_Y - 38)
    var fshape := CollisionShape2D.new()
    var frect := RectangleShape2D.new()
    frect.size = Vector2(48, 82)
    fshape.shape = frect
    finish.add_child(fshape)
    finish.body_entered.connect(_on_finish_entered)
    add_child(finish)

func _platform(pos: Vector2, size: Vector2, tint: Color) -> StaticBody2D:
    var body := StaticBody2D.new()
    body.position = pos + Vector2(size.x / 2.0, size.y / 2.0)
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = size
    shape.shape = rect
    body.add_child(shape)
    var visual := ColorRect.new()
    visual.position = -size / 2.0
    visual.size = size
    visual.color = tint
    body.add_child(visual)
    var top := ColorRect.new()
    top.position = Vector2(-size.x / 2.0, -size.y / 2.0)
    top.size = Vector2(size.x, 8)
    top.color = Color("#a6e36f")
    body.add_child(top)
    add_child(body)
    return body

func _spikes(pos: Vector2, width: float) -> void:
    var area := Area2D.new()
    area.position = pos
    area.add_to_group("deadly")
    var shape := CollisionShape2D.new()
    var rect := RectangleShape2D.new()
    rect.size = Vector2(width, 20)
    shape.shape = rect
    area.add_child(shape)
    area.body_entered.connect(_on_spike_entered)
    add_child(area)
    var points := PackedVector2Array()
    var count := int(width / 18.0)
    for i in count:
        var x := i * 18.0
        points.append(Vector2(x, 12))
        points.append(Vector2(x + 9, -9))
        points.append(Vector2(x + 18, 12))
    var poly := Polygon2D.new()
    poly.position = pos
    poly.polygon = points
    poly.color = Color("#e84855")
    add_child(poly)

func _draw_cloud(pos: Vector2) -> void:
    for offset in [Vector2(0, 8), Vector2(18, 0), Vector2(38, 8), Vector2(12, 14), Vector2(30, 14)]:
        var block := ColorRect.new()
        block.position = pos + offset
        block.size = Vector2(28, 16)
        block.color = Color("#f4fbff")
        block.z_index = -5
        add_child(block)

func _build_ui() -> void:
    ui_layer = CanvasLayer.new()
    add_child(ui_layer)
    var panel := ColorRect.new()
    panel.position = Vector2(16, 14)
    panel.size = Vector2(205, 42)
    panel.color = Color("#26324a")
    panel.modulate.a = 0.9
    ui_layer.add_child(panel)
    death_label = Label.new()
    death_label.position = Vector2(28, 20)
    death_label.text = "LEVEL 01   •   DEATHS 0"
    death_label.add_theme_font_size_override("font_size", 18)
    death_label.add_theme_color_override("font_color", Color.WHITE)
    ui_layer.add_child(death_label)

    message_label = Label.new()
    message_label.position = Vector2(235, 18)
    message_label.size = Vector2(650, 36)
    message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    message_label.add_theme_font_size_override("font_size", 17)
    message_label.add_theme_color_override("font_color", Color("#26324a"))
    ui_layer.add_child(message_label)

    _load_control_layout()
    _touch_button("◀", Vector2(24, 430), "move_left")
    _touch_button("▶", Vector2(112, 430), "move_right")
    _touch_button("JUMP", Vector2(810, 420), "jump")
    var edit_button := Button.new()
    edit_button.text = "EDIT"
    edit_button.position = Vector2(700, 14)
    edit_button.size = Vector2(64, 42)
    edit_button.pressed.connect(_toggle_control_editor)
    ui_layer.add_child(edit_button)
    var smaller := Button.new()
    smaller.text = "A−"
    smaller.position = Vector2(770, 14)
    smaller.size = Vector2(42, 42)
    smaller.pressed.connect(func(): _resize_selected_control(-8.0))
    ui_layer.add_child(smaller)
    var larger := Button.new()
    larger.text = "A+"
    larger.position = Vector2(818, 14)
    larger.size = Vector2(42, 42)
    larger.pressed.connect(func(): _resize_selected_control(8.0))
    ui_layer.add_child(larger)
    var restart_button := Button.new()
    restart_button.text = "↻"
    restart_button.position = Vector2(866, 14)
    restart_button.size = Vector2(48, 42)
    restart_button.pressed.connect(_restart_level)
    ui_layer.add_child(restart_button)

func _touch_button(caption: String, pos: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.position = control_positions.get(action, pos)
    var button_size: float = control_sizes.get(action, 76.0)
    button.size = Vector2(button_size, button_size)
    button.add_theme_font_size_override("font_size", 23 if action != "jump" else 18)
    button.focus_mode = Control.FOCUS_NONE
    button.button_down.connect(func(): _set_touch_action(action, true))
    button.button_up.connect(func(): _set_touch_action(action, false))
    button.gui_input.connect(_on_control_gui_input.bind(button, action))
    control_buttons[action] = button
    ui_layer.add_child(button)

func _set_touch_action(action: String, pressed: bool) -> void:
    if control_edit_mode:
        return
    match action:
        "move_left":
            left_held = pressed
        "move_right":
            right_held = pressed
        "jump":
            if pressed and not jump_held and is_instance_valid(player):
                player.jump_requested = true
            jump_held = pressed

func _toggle_control_editor() -> void:
    control_edit_mode = not control_edit_mode
    left_held = false
    right_held = false
    jump_held = false
    selected_control = ""
    dragging_control = ""
    for action in control_buttons:
        var button: Button = control_buttons[action]
        button.modulate = Color(1.0, 0.82, 0.45, 1.0) if control_edit_mode else Color.WHITE
    _show_message("DRAG BUTTONS • SELECT ONE, THEN USE A− / A+ • EDIT TO SAVE" if control_edit_mode else "CONTROLS SAVED", 2.5)
    if not control_edit_mode:
        _save_control_layout()

func _resize_selected_control(amount: float) -> void:
    if not control_edit_mode or selected_control == "":
        return
    var button: Button = control_buttons[selected_control]
    var new_size: float = clampf(button.size.x + amount, 44.0, 150.0)
    button.size = Vector2(new_size, new_size)
    control_sizes[selected_control] = new_size
    _save_control_layout()

func _on_control_gui_input(event: InputEvent, button: Button, action: String) -> void:
    if not control_edit_mode:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            selected_control = action
            dragging_control = action
            drag_offset = button.position - get_viewport().get_mouse_position()
        elif dragging_control == action:
            dragging_control = ""
            _save_control_layout()
        button.accept_event()
    elif event is InputEventMouseMotion and dragging_control == action:
        var viewport_size := get_viewport().get_visible_rect().size
        var new_pos := get_viewport().get_mouse_position() + drag_offset
        button.position = Vector2(clampf(new_pos.x, 0.0, viewport_size.x - button.size.x), clampf(new_pos.y, 0.0, viewport_size.y - button.size.y))
        control_positions[action] = button.position
        button.accept_event()

func _load_control_layout() -> void:
    control_config.load("user://pixel_quest_controls.cfg")
    for action in ["move_left", "move_right", "jump"]:
        var saved_position = control_config.get_value("controls", action + "_position", null)
        if saved_position is Vector2:
            control_positions[action] = saved_position
        control_sizes[action] = float(control_config.get_value("controls", action + "_size", 76.0))

func _save_control_layout() -> void:
    for action in control_buttons:
        var button: Button = control_buttons[action]
        control_positions[action] = button.position
        control_sizes[action] = button.size.x
        control_config.set_value("controls", action + "_position", button.position)
        control_config.set_value("controls", action + "_size", button.size.x)
    control_config.save("user://pixel_quest_controls.cfg")

func _spawn_player() -> void:
    player = PLAYER_SCRIPT.new() as PQPlayer
    player.position = Vector2(70, FLOOR_Y - 45)
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(18, 27)
    collision.shape = shape
    player.add_child(collision)
    player.died.connect(_player_died)
    add_child(player)

func _on_crumble_touched(body: Node2D) -> void:
    if body == player and not collapsed:
        collapsed = true
        collapse_timer = 0.35
        player.controls_enabled = false
        if is_instance_valid(crumble_platform):
            crumble_platform.get_child(0).set_deferred("disabled", true)
            crumble_platform.visible = false
        if is_instance_valid(crumble_visual):
            crumble_visual.visible = false
        _show_message("THE FLOOR WASN'T SAFE!", 1.0)
        _play_tone(170.0, 0.13)

func _on_spike_entered(body: Node2D) -> void:
    if body == player:
        _player_died()

func _on_finish_entered(body: Node2D) -> void:
    if body == player:
        _win_level()

func _player_died() -> void:
    if not is_instance_valid(player) or not player.controls_enabled:
        return
    player.controls_enabled = false
    deaths += 1
    death_label.text = "LEVEL 01   •   DEATHS %d" % deaths
    _show_message("OOPS. TRY AGAIN.", 0.8)
    _play_tone(95.0, 0.22)
    _restart_level(false)

func _restart_level(reset_deaths := false) -> void:
    left_held = false
    right_held = false
    jump_held = false
    touch_points.clear()
    if is_instance_valid(player):
        player.touch_control_active = false
    if reset_deaths:
        deaths = 0
    if is_instance_valid(player):
        player.queue_free()
    collapsed = false
    if is_instance_valid(crumble_platform):
        crumble_platform.visible = true
        crumble_platform.get_child(0).set_deferred("disabled", false)
    if is_instance_valid(crumble_visual):
        crumble_visual.visible = true
    moving_direction = 1.0
    if is_instance_valid(moving_platform):
        moving_platform.position.x = moving_start_x
    _spawn_player()
    death_label.text = "LEVEL 01   •   DEATHS %d" % deaths

func _win_level() -> void:
    if not is_instance_valid(player):
        return
    player.controls_enabled = false
    _show_message("LEVEL CLEAR!  •  R = RESTART", 999.0)
    _play_tone(660.0, 0.35)

func _show_message(value: String, duration: float) -> void:
    message_label.text = value
    if duration < 10.0:
        get_tree().create_timer(duration).timeout.connect(func():
            if is_instance_valid(message_label) and message_label.text == value:
                message_label.text = ""
        )

func _play_tone(frequency: float, duration: float) -> void:
    # Lightweight generated sound: no external audio asset required.
    if not is_instance_valid(audio_player):
        audio_player = AudioStreamPlayer.new()
        var generator := AudioStreamGenerator.new()
        generator.mix_rate = 22050
        generator.buffer_length = 0.25
        audio_player.stream = generator
        add_child(audio_player)
        audio_player.play()
    var playback := audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
    if playback == null:
        return
    var frames := int(22050.0 * duration)
    for i in frames:
        var envelope := 1.0 - float(i) / frames
        var sample := sin(TAU * frequency * float(i) / 22050.0) * envelope * 0.16
        playback.push_frame(Vector2(sample, sample))
