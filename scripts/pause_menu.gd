extends CanvasLayer

@onready var pause_panel: Control = $PausePanel
@onready var continue_button: Button = $PausePanel/Panel/VBox/ContinueButton
@onready var restart_button: Button = $PausePanel/Panel/VBox/RestartButton

var _is_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_button.pressed.connect(_continue_game)
	restart_button.pressed.connect(_restart_level)
	pause_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	_set_paused(not _is_paused)

func _set_paused(paused: bool) -> void:
	_is_paused = paused
	pause_panel.visible = paused
	get_tree().paused = paused
	if paused:
		continue_button.grab_focus()

func _continue_game() -> void:
	_set_paused(false)

func _restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()