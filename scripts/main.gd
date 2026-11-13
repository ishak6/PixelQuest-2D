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
var game_camera: Camera2D
var level_background: ColorRect
var hud_panel: ColorRect
var utility_buttons: Dictionary = {}
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
var custom_control_layout := false
var editor_touch_index := -1
var editor_touch_offset := Vector2.ZERO

func _ready() -> void:
    _configure_viewport()
    get_viewport().size_changed.connect(_on_viewport_resized)
    _setup_input()
    _build_level()
    _build_ui()
    _spawn_player()
    _show_message("THE FAKE BEGINNING  •  Reach the door. Trust nothing.", 3.5)

func _configure_viewport() -> void:
    game_camera = Camera2D.new()
    game_camera.position = Vector2(WORLD_W * 0.5, 270.0)
    game_camera.enabled = true
    add_child(game_camera)
    _fit_camera_to_scene()

func _on_viewport_resized() -> void:
    _fit_camera_to_scene()
    _layout_ui()
    _refresh_touch_controls()

func _fit_camera_to_scene() -> void:
    if not is_instance_valid(game_camera):
        return
    var viewport_size := get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    var zoom_factor: float = minf(viewport_size.x / WORLD_W, viewport_size.y / 540.0)
    zoom_factor = maxf(zoom_factor, 0.1)
    game_camera.zoom = Vector2(zoom_factor, zoom_factor)
    if is_instance_valid(level_background):
        var visible_world_size := viewport_size / zoom_factor
        level_background.position = game_camera.position - visible_world_size * 0.5
        level_background.size = visible_world_size

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
    # EDIT mode: drag a control with one finger without triggering gameplay.
    if control_edit_mode:
        if event is InputEventScreenTouch:
            if event.pressed and editor_touch_index == -1:
                for action in control_buttons:
                    var button: Button = control_buttons[action]
                    if button.get_global_rect().has_point(event.position):
                        selected_control = action
                        dragging_control = action
                        editor_touch_index = event.index
                        editor_touch_offset = button.position - event.position
                        button.modulate = Color(1.0, 0.72, 0.28, 1.0)
                        break
            elif not event.pressed and event.index == editor_touch_index:
                editor_touch_index = -1
                dragging_control = ""
                _save_control_layout()
            return
        if event is InputEventScreenDrag and event.index == editor_touch_index and dragging_control != "":
            var dragged: Button = control_buttons[dragging_control]
            var viewport_size := get_viewport().get_visible_rect().size
            var next_position := event.position + editor_touch_offset
            dragged.position = Vector2(
                clampf(next_position.x, 0.0, maxf(0.0, viewport_size.x - dragged.size.x)),
                clampf(next_position.y, 0.0, maxf(0.0, viewport_size.y - dragged.size.y))
            )
            control_positions[dragging_control] = dragged.position
            _refresh_editor_highlight()
            return

    # Each finger is tracked independently, allowing move + jump together.
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
    level_background = ColorRect.new()
    level_background.color = Color("#91d7ef")
    level_background.size = Vector2(WORLD_W, 540)
    level_background.z_index = -20
    add_child(level_background)
    _fit_camera_to_scene()
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
    hud_panel = ColorRect.new()
    hud_panel.position = Vector2(16, 14)
    hud_panel.size = Vector2(205, 42)
    hud_panel.color = Color("#26324a")
    hud_panel.modulate.a = 0.9
    ui_layer.add_child(hud_panel)
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
    utility_buttons["edit"] = edit_button
    var smaller := Button.new()
    smaller.text = "A−"
    smaller.position = Vector2(770, 14)
    smaller.size = Vector2(42, 42)
    smaller.pressed.connect(func(): _resize_selected_control(-8.0))
    ui_layer.add_child(smaller)
    utility_buttons["smaller"] = smaller
    var larger := Button.new()
    larger.text = "A+"
    larger.position = Vector2(818, 14)
    larger.size = Vector2(42, 42)
    larger.pressed.connect(func(): _resize_selected_control(8.0))
    ui_layer.add_child(larger)
    utility_buttons["larger"] = larger
    var restart_button := Button.new()
    restart_button.text = "↻"
    restart_button.position = Vector2(866, 14)
    restart_button.size = Vector2(48, 42)
    restart_button.pressed.connect(_restart_level)
    ui_layer.add_child(restart_button)
    utility_buttons["restart"] = restart_button
    _layout_ui()

func _layout_ui() -> void:
    if not is_instance_valid(ui_layer):
        return
    var viewport_size := get_viewport().get_visible_rect().size
    var w: float = viewport_size.x
    var h: float = viewport_size.y
    var compact: bool = w < 700.0
    if is_instance_valid(hud_panel):
        hud_panel.position = Vector2(12, 12)
        hud_panel.size = Vector2(205, 42)
    if is_instance_valid(death_label):
        death_label.position = Vector2(24, 18)
    if is_instance_valid(message_label):
        message_label.position = Vector2(12, 108 if compact else 14)
        message_label.size = Vector2(maxf(100.0, w - 24.0), 38)
        message_label.add_theme_font_size_override("font_size", 14 if compact else 17)
    var top_y: float = 66.0 if compact else 12.0
    var button_h: float = 38.0 if compact else 42.0
    var restart_w: float = 44.0
    var edit_w: float = 58.0 if compact else 64.0
    var small_w: float = 38.0 if compact else 42.0
    var gap: float = 5.0
    var right_edge: float = w - 12.0
    var restart_button: Button = utility_buttons["restart"]
    var larger: Button = utility_buttons["larger"]
    var smaller: Button = utility_buttons["smaller"]
    var edit_button: Button = utility_buttons["edit"]
    restart_button.size = Vector2(restart_w, button_h)
    restart_button.position = Vector2(right_edge - restart_w, top_y)
    larger.size = Vector2(small_w, button_h)
    larger.position = Vector2(restart_button.position.x - gap - small_w, top_y)
    smaller.size = Vector2(small_w, button_h)
    smaller.position = Vector2(larger.position.x - gap - small_w, top_y)
    edit_button.size = Vector2(edit_w, button_h)
    edit_button.position = Vector2(smaller.position.x - gap - edit_w, top_y)
    var default_size: float = clampf(minf(w, h) * 0.16, 64.0, 92.0)
    var bottom_y: float = h - default_size - 18.0
    var defaults := {
        "move_left": Vector2(18.0, bottom_y),
        "move_right": Vector2(28.0 + default_size, bottom_y),
        "jump": Vector2(w - default_size - 18.0, bottom_y)
    }
    for action in control_buttons:
        var control: Button = control_buttons[action]
        if not custom_control_layout:
            control.size = Vector2(default_size, default_size)
            control.position = defaults[action]
        else:
            var normalized_position: Vector2 = control_positions.get(action, Vector2(0.0, 0.0))
            control.position = Vector2(
                clampf(normalized_position.x * w, 0.0, maxf(0.0, w - control.size.x)),
                clampf(normalized_position.y * h, 0.0, maxf(0.0, h - control.size.y))
            )
    _refresh_editor_highlight()

func _touch_button(caption: String, pos: Vector2, action: String) -> void:
    var button := Button.new()
    button.text = caption
    button.position = control_positions.get(action, pos)
    var button_size: float = control_sizes.get(action, 76.0)
    button.size = Vector2(button_size, button_size)
    button.add_theme_font_size_override("font_size", 23 if action != "jump" else 18)
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_filter = Control.MOUSE_FILTER_STOP
    _style_touch_button(button, action)
    button.gui_input.connect(_on_control_gui_input.bind(button, action))
    control_buttons[action] = button
    ui_layer.add_child(button)

func _style_touch_button(button: Button, action: String) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#26324a", 0.78)
    normal.border_color = Color("#ffffff", 0.72)
    normal.set_border_width_all(2)
    normal.set_corner_radius_all(18)
    normal.shadow_color = Color("#101827", 0.28)
    normal.shadow_size = 5
    normal.content_margin_left = 8
    normal.content_margin_right = 8
    normal.content_margin_top = 8
    normal.content_margin_bottom = 8
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color("#7656a8", 0.96)
    pressed.border_color = Color("#ffd166")
    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#3c4d70", 0.92)
    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color("#ffd166"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)

func _refresh_editor_highlight() -> void:
    for action in control_buttons:
        var control: Button = control_buttons[action]
        if control_edit_mode and action == selected_control:
            control.modulate = Color(1.0, 0.72, 0.28, 1.0)
        elif control_edit_mode:
            control.modulate = Color(1.0, 0.88, 0.62, 1.0)
        else:
            control.modulate = Color.WHITE

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
    editor_touch_index = -1
    _refresh_editor_highlight()
    _show_message("DRAG BUTTONS • TAP ONE, THEN USE A− / A+ • EDIT TO SAVE" if control_edit_mode else "CONTROLS SAVED", 2.5)
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
        if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
            _set_touch_action(action, event.pressed)
            button.accept_event()
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
    custom_control_layout = bool(control_config.get_value("controls", "customized", false))
    for action in ["move_left", "move_right", "jump"]:
        var normalized_position = control_config.get_value("controls", action + "_normalized_position", null)
        if normalized_position is Vector2:
            control_positions[action] = normalized_position
        control_sizes[action] = float(control_config.get_value("controls", action + "_size", 76.0))

func _save_control_layout() -> void:
    var viewport_size := get_viewport().get_visible_rect().size
    if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
        return
    custom_control_layout = true
    for action in control_buttons:
        var button: Button = control_buttons[action]
        var normalized_position := Vector2(button.position.x / viewport_size.x, button.position.y / viewport_size.y)
        control_positions[action] = normalized_position
        control_sizes[action] = button.size.x
        control_config.set_value("controls", action + "_normalized_position", normalized_position)
        control_config.set_value("controls", action + "_size", button.size.x)
    control_config.set_value("controls", "customized", true)
    control_config.save("user://pixel_quest_controls.cfg")

func _spawn_player() -> void:
    player = PLAYER_SCRIPT.new() as PQPlayer
    player.position = Vector2(70, FLOOR_Y - 14)
    player.z_index = 20
    player.visible = true
    player.modulate = Color.WHITE
    var collision := CollisionShape2D.new()
    var shape := RectangleShape2D.new()
    shape.size = Vector2(22, 36)
    collision.shape = shape
    player.add_child(collision)
    player.died.connect(_player_died)
    player.death_animation_finished.connect(_finish_player_death)
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
    if not is_instance_valid(player) or player.dying:
        return
    player.begin_death()

func _finish_player_death() -> void:
    if not is_instance_valid(player):
        return
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
    editor_touch_index = -1
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
