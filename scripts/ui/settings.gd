extends Control

## Ajustes globales que se aplican en vivo y se guardan en user://settings.cfg:
## volúmenes, pantalla completa e idioma. Además, borrar el progreso (niveles
## completados y récords), con confirmación: el botón pide una segunda pulsación.

## Segundos que espera la confirmación de "borrar progreso".
const ERASE_CONFIRM_TIME := 3.0

@onready var _master_volume: HSlider = %VolumeSlider
@onready var _music_volume: HSlider = %MusicVolumeSlider
@onready var _sfx_volume: HSlider = %SfxVolumeSlider
@onready var _fullscreen: CheckBox = %FullscreenCheck
@onready var _language: OptionButton = %LanguageOption
@onready var _reset_button: Button = %ResetButton
@onready var _erase_button: Button = %EraseButton
@onready var _back_button: Button = %BackButton

var _settings: Node
var _erase_armed := false
var _erase_timer: SceneTreeTimer

func _ready() -> void:
	_settings = get_node("/root/SettingsManager")
	_show_values()
	_master_volume.value_changed.connect(_settings.set_master_volume)
	_music_volume.value_changed.connect(_settings.set_music_volume)
	_sfx_volume.value_changed.connect(_on_sfx_volume_changed)
	_fullscreen.toggled.connect(_settings.set_fullscreen)

	# Un ítem por idioma disponible, cada uno con su nombre en su idioma.
	for code in Languages.available():
		_language.add_item(Languages.name_of(code))
		_language.set_item_metadata(_language.item_count - 1, code)
		if code == _settings.language:
			_language.select(_language.item_count - 1)
	_language.item_selected.connect(_on_language_selected)

	_reset_button.pressed.connect(_on_reset_pressed)
	_erase_button.pressed.connect(_on_erase_pressed)
	_back_button.pressed.connect(_on_back_pressed)
	_back_button.grab_focus()

## Muestra los valores guardados sin disparar las señales (no re-guarda ni suena).
func _show_values() -> void:
	_master_volume.set_value_no_signal(_settings.master_volume)
	_music_volume.set_value_no_signal(_settings.music_volume)
	_sfx_volume.set_value_no_signal(_settings.sfx_volume)
	_fullscreen.set_pressed_no_signal(_settings.fullscreen)

func _on_sfx_volume_changed(value: float) -> void:
	_settings.set_sfx_volume(value)
	Sfx.preview()

func _on_language_selected(index: int) -> void:
	_settings.set_language(String(_language.get_item_metadata(index)))

func _on_reset_pressed() -> void:
	_settings.reset_to_defaults()
	_show_values()

## Primera pulsación: pide confirmar ("¿Seguro?") por unos segundos. Segunda:
## borra niveles completados y récords.
func _on_erase_pressed() -> void:
	if not _erase_armed:
		_erase_armed = true
		_erase_button.text = "SETTINGS_ERASE_SURE"
		_erase_timer = get_tree().create_timer(ERASE_CONFIRM_TIME)
		_erase_timer.timeout.connect(_disarm_erase.bind(_erase_timer))
		return
	_erase_armed = false
	ScoreBoard.reset_progress()
	_erase_button.text = "SETTINGS_ERASED"
	_erase_button.disabled = true

func _disarm_erase(timer: SceneTreeTimer) -> void:
	if timer == _erase_timer and _erase_armed:
		_erase_armed = false
		_erase_button.text = "SETTINGS_ERASE"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_back_pressed()
