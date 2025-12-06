# RecordingSDK Editor Plugin for Godot 3.x
# Automatically registers the SDK as an autoload and provides configuration UI

tool
extends EditorPlugin

const AUTOLOAD_NAME = "RecordingSDK"
const SDK_PATH = "res://addons/recording_sdk/RecordingSDK.gd"
const SETTINGS_PREFIX = "recording_sdk/"

# Default settings
const DEFAULT_SETTINGS = {
	"server_url": "ws://localhost:9876",
	"auto_connect": true,
	"auto_reconnect": true,
	"reconnect_delay": 2.0,
	"max_reconnect_attempts": 5,
	"enable_debug_logging": false
}

var _settings_panel: Control = null


func _enter_tree() -> void:
	# Register project settings
	_register_project_settings()
	
	# Add autoload
	if not _is_autoload_registered():
		add_autoload_singleton(AUTOLOAD_NAME, SDK_PATH)
		print("[RecordingSDK] Autoload registered")
	
	# Add settings panel to Project Settings
	_add_settings_panel()


func _exit_tree() -> void:
	# Remove settings panel
	_remove_settings_panel()
	
	# Note: We don't remove the autoload on disable to prevent breaking 
	# games that depend on it. Users can manually remove if needed.


func _register_project_settings() -> void:
	# Server URL
	_add_setting(
		"server_url",
		TYPE_STRING,
		DEFAULT_SETTINGS.server_url,
		PROPERTY_HINT_NONE,
		"WebSocket URL of the recording server"
	)
	
	# Auto-connect on game start
	_add_setting(
		"auto_connect",
		TYPE_BOOL,
		DEFAULT_SETTINGS.auto_connect,
		PROPERTY_HINT_NONE,
		"Automatically connect to recorder when game starts"
	)
	
	# Auto-reconnect
	_add_setting(
		"auto_reconnect",
		TYPE_BOOL,
		DEFAULT_SETTINGS.auto_reconnect,
		PROPERTY_HINT_NONE,
		"Automatically reconnect if connection is lost"
	)
	
	# Reconnect delay
	_add_setting(
		"reconnect_delay",
		TYPE_REAL,
		DEFAULT_SETTINGS.reconnect_delay,
		PROPERTY_HINT_RANGE,
		"0.5,10.0,0.5"
	)
	
	# Max reconnect attempts
	_add_setting(
		"max_reconnect_attempts",
		TYPE_INT,
		DEFAULT_SETTINGS.max_reconnect_attempts,
		PROPERTY_HINT_RANGE,
		"1,20,1"
	)
	
	# Debug logging
	_add_setting(
		"enable_debug_logging",
		TYPE_BOOL,
		DEFAULT_SETTINGS.enable_debug_logging,
		PROPERTY_HINT_NONE,
		"Enable verbose debug logging"
	)


func _add_setting(key: String, type: int, default_value, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	var full_key = SETTINGS_PREFIX + key
	
	if not ProjectSettings.has_setting(full_key):
		ProjectSettings.set_setting(full_key, default_value)
	
	ProjectSettings.set_initial_value(full_key, default_value)
	
	var property_info = {
		"name": full_key,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}
	ProjectSettings.add_property_info(property_info)


func _is_autoload_registered() -> bool:
	# Check if autoload already exists in project settings
	var autoloads = ProjectSettings.get_setting("autoload/" + AUTOLOAD_NAME)
	return autoloads != null


func _add_settings_panel() -> void:
	# Settings are now in Project Settings, no custom dock needed
	pass


func _remove_settings_panel() -> void:
	pass


func get_plugin_name() -> String:
	return "RecordingSDK"


func get_plugin_icon() -> Texture:
	return preload("res://addons/recording_sdk/icon.png")
