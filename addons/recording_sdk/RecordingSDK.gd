# GameRecording SDK for Godot (GDScript)
# 
# This SDK allows your Godot game to communicate with an Electron recording application
# to automatically record gameplay moments.
#
# Usage:
#   var recording_sdk = RecordingSDK.new()
#   recording_sdk.connect_to_recorder()
#   
#   # Start recording
#   var recording_id = await recording_sdk.start_recording("boss_fight_dragon")
#   
#   # Stop recording after 3 seconds
#   await get_tree().create_timer(3.0).timeout
#   await recording_sdk.stop_recording(recording_id)

extends Node
class_name RecordingSDK

# Signals
signal connected_to_recorder()
signal disconnected_from_recorder()
signal recording_started(recording_id: String)
signal recording_stopped(recording_id: String, file_path: String)
signal auto_record_settings_changed(enabled: bool)
signal error_occurred(error_message: String)

# Configuration
var server_url: String = "ws://localhost:9876"
var auto_reconnect: bool = true
var reconnect_delay: float = 2.0
var max_reconnect_attempts: int = 5

# Internal state
var _websocket: WebSocketClient
var _is_connected: bool = false
var _auto_record_enabled: bool = true
var _reconnect_attempts: int = 0
var _pending_responses: Dictionary = {}
var _current_recording_id: String = ""

func _init():
	_websocket = WebSocketClient.new()

func _ready():
	# Connect WebSocket signals
	_websocket.connection_established.connect(_on_connection_established)
	_websocket.connection_closed.connect(_on_connection_closed)
	_websocket.connection_error.connect(_on_connection_error)
	_websocket.data_received.connect(_on_data_received)

func _process(_delta):
	if _websocket:
		_websocket.poll()

# Connect to the Electron recording application
func connect_to_recorder() -> void:
	print("[RecordingSDK] Connecting to recorder at %s..." % server_url)
	var err = _websocket.connect_to_url(server_url)
	if err != OK:
		push_error("[RecordingSDK] Failed to connect: %s" % err)
		emit_signal("error_occurred", "Failed to connect to recorder")

# Disconnect from the recorder
func disconnect_from_recorder() -> void:
	if _is_connected:
		_websocket.close()
		_is_connected = false

# Start recording with event_id
# Returns the recording ID if successful, empty string otherwise
func start_recording(event_id: String) -> String:
	if not _is_connected:
		push_error("[RecordingSDK] Not connected to recorder")
		emit_signal("error_occurred", "Not connected to recorder")
		return ""
	
	if not _auto_record_enabled:
		print("[RecordingSDK] Auto-record is disabled by user")
		return ""
	
	if event_id.is_empty():
		push_warning("[RecordingSDK] Starting recording with empty event_id")
	
	var message = {
		"type": "start_recording",
		"timestamp": int(Time.get_unix_time_from_system() * 1000),
		"metadata": {
			"event_id": event_id
		}
	}
	
	_send_message(message)
	
	# Wait for response (simplified - in production use awaitable signals)
	await get_tree().create_timer(0.1).timeout
	return _current_recording_id

# Stop recording
# delay_seconds: Optional delay before stopping (e.g., 3 seconds after boss dies)
func stop_recording(recording_id: String, delay_seconds: float = 0.0) -> void:
	if not _is_connected:
		push_error("[RecordingSDK] Not connected to recorder")
		return
	
	if recording_id.is_empty():
		push_error("[RecordingSDK] Invalid recording ID")
		return
	
	# Wait for delay if specified
	if delay_seconds > 0.0:
		print("[RecordingSDK] Stopping recording in %.1f seconds..." % delay_seconds)
		await get_tree().create_timer(delay_seconds).timeout
	
	var message = {
		"type": "stop_recording",
		"timestamp": int(Time.get_unix_time_from_system() * 1000),
		"recording_id": recording_id
	}
	
	_send_message(message)

# Request current settings from the recorder
func request_settings() -> void:
	if not _is_connected:
		return
	
	var message = {
		"type": "get_settings",
		"timestamp": int(Time.get_unix_time_from_system() * 1000)
	}
	
	_send_message(message)

# Check if currently connected
func is_connected() -> bool:
	return _is_connected

# Check if auto-record is enabled
func is_auto_record_enabled() -> bool:
	return _auto_record_enabled

# Get current recording ID (empty if not recording)
func get_current_recording_id() -> String:
	return _current_recording_id

# Internal: Send message to Electron app
func _send_message(message: Dictionary) -> void:
	var json = JSON.stringify(message)
	var err = _websocket.send_text(json)
	if err != OK:
		push_error("[RecordingSDK] Failed to send message: %s" % err)

# Internal: Handle incoming messages
func _handle_message(json_string: String) -> void:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[RecordingSDK] Failed to parse JSON: %s" % json_string)
		return
	
	var message = json.data
	if not message is Dictionary:
		return
	
	var msg_type = message.get("type", "")
	
	match msg_type:
		"settings":
			_auto_record_enabled = message.get("auto_record_enabled", true)
			print("[RecordingSDK] Auto-record: %s" % ("ON" if _auto_record_enabled else "OFF"))
			emit_signal("auto_record_settings_changed", _auto_record_enabled)
		
		"recording_started":
			_current_recording_id = message.get("recording_id", "")
			print("[RecordingSDK] Recording started: %s" % _current_recording_id)
			emit_signal("recording_started", _current_recording_id)
		
		"recording_stopped":
			var recording_id = message.get("recording_id", "")
			var file_path = message.get("file_path", "")
			var duration = message.get("duration", 0.0)
			var file_size = message.get("file_size", 0)
			
			print("[RecordingSDK] Recording stopped: %s" % file_path)
			print("[RecordingSDK] Duration: %.1fs, Size: %.2f MB" % [duration, file_size / 1024.0 / 1024.0])
			
			if recording_id == _current_recording_id:
				_current_recording_id = ""
			
			emit_signal("recording_stopped", recording_id, file_path)
		
		"pong":
			# Heartbeat response
			pass
		
		"error":
			var error_msg = message.get("message", "Unknown error")
			push_error("[RecordingSDK] Server error: %s" % error_msg)
			emit_signal("error_occurred", error_msg)

# Internal: Connection established
func _on_connection_established(_protocol: String) -> void:
	print("[RecordingSDK] Connected to recorder!")
	_is_connected = true
	_reconnect_attempts = 0
	emit_signal("connected_to_recorder")
	
	# Request settings immediately
	request_settings()
	
	# Start heartbeat
	_start_heartbeat()

# Internal: Connection closed
func _on_connection_closed(_was_clean: bool) -> void:
	print("[RecordingSDK] Disconnected from recorder")
	_is_connected = false
	_current_recording_id = ""
	emit_signal("disconnected_from_recorder")
	
	# Attempt reconnection
	if auto_reconnect and _reconnect_attempts < max_reconnect_attempts:
		_reconnect_attempts += 1
		print("[RecordingSDK] Reconnecting in %.1fs (attempt %d/%d)..." % [reconnect_delay, _reconnect_attempts, max_reconnect_attempts])
		await get_tree().create_timer(reconnect_delay).timeout
		connect_to_recorder()

# Internal: Connection error
func _on_connection_error() -> void:
	push_error("[RecordingSDK] Connection error")
	_is_connected = false
	emit_signal("error_occurred", "Connection error")

# Internal: Data received
func _on_data_received() -> void:
	var packet = _websocket.get_peer(1).get_packet()
	var json_string = packet.get_string_from_utf8()
	_handle_message(json_string)

# Internal: Send periodic heartbeat
func _start_heartbeat() -> void:
	while _is_connected:
		await get_tree().create_timer(30.0).timeout
		if _is_connected:
			var message = {
				"type": "ping",
				"timestamp": int(Time.get_unix_time_from_system() * 1000)
			}
			_send_message(message)

# Cleanup
func _exit_tree():
	disconnect_from_recorder()
