# Example usage of RecordingSDK in a Godot game
# 
# This script demonstrates how to use the RecordingSDK to automatically
# record gameplay moments. The developer chooses when and what to record.

extends Node

var recording_sdk: RecordingSDK
var current_recording_id: String = ""

func _ready():
	# Create and initialize the SDK
	recording_sdk = RecordingSDK.new()
	add_child(recording_sdk)
	
	# Connect to signals
	recording_sdk.connected_to_recorder.connect(_on_recorder_connected)
	recording_sdk.disconnected_from_recorder.connect(_on_recorder_disconnected)
	recording_sdk.recording_started.connect(_on_recording_started)
	recording_sdk.recording_stopped.connect(_on_recording_stopped)
	recording_sdk.auto_record_settings_changed.connect(_on_auto_record_changed)
	recording_sdk.error_occurred.connect(_on_error)
	
	# Connect to the Electron recorder app
	recording_sdk.connect_to_recorder()

# Generic function to start auto-recording
# event_id: A unique identifier for this clip (e.g., "boss_fight_dragon")
func auto_record_start(event_id: String):
	print("Starting auto-record: %s" % event_id)
	
	# Start recording
	current_recording_id = await recording_sdk.start_recording(event_id)
	
	if current_recording_id.is_empty():
		print("Failed to start recording (auto-record might be disabled)")
	else:
		print("Recording started: %s" % current_recording_id)

# Generic function to stop auto-recording
# delay_seconds: Optional delay before stopping (e.g., 3.0 for 3 seconds)
func auto_record_stop(delay_seconds: float = 0.0):
	if current_recording_id.is_empty():
		print("No active recording to stop")
		return
	
	print("Stopping auto-record in %.1f seconds..." % delay_seconds)
	
	# Stop recording with optional delay
	await recording_sdk.stop_recording(
		current_recording_id,
		delay_seconds
	)
	
	current_recording_id = ""

# ============================================================================
# EXAMPLE USAGE - Developer implements these based on their game
# ============================================================================

# Example 1: Boss fight recording
func example_boss_fight():
	# Boss spawns - start recording
	auto_record_start("boss_fight_ancient_dragon")
	
	# Boss defeated - stop recording 3 seconds later
	await auto_record_stop(3.0)

# Example 2: Speedrun recording
func example_speedrun():
	# Level starts
	auto_record_start("speedrun_level_1")
	
	# Level completed
	await auto_record_stop(2.0)

# Example 3: Achievement unlock recording
func example_achievement():
	# Start recording when close to unlocking
	auto_record_start("achievement_first_blood")
	
	# Achievement unlocked
	await auto_record_stop(2.0)

# Example 4: PvP match recording
func example_pvp_match():
	# Match starts
	auto_record_start("pvp_deathmatch")
	
	# Match ends
	await auto_record_stop(5.0)

# Example 5: Custom event
func example_custom_event():
	# Any custom event
	auto_record_start("my_custom_event")
	
	# Event completes
	await auto_record_stop(1.0)

# ============================================================================
# Signal handlers
# ============================================================================

func _on_recorder_connected():
	print("✓ Connected to recorder app")

func _on_recorder_disconnected():
	print("✗ Disconnected from recorder app")
	current_recording_id = ""

func _on_recording_started(recording_id: String):
	print("✓ Recording started: %s" % recording_id)

func _on_recording_stopped(recording_id: String, file_path: String):
	print("✓ Recording saved: %s" % file_path)

func _on_auto_record_changed(enabled: bool):
	print("Auto-record is now: %s" % ("ON" if enabled else "OFF"))

func _on_error(error_message: String):
	print("✗ Error: %s" % error_message)

# ============================================================================
# Testing with keyboard shortcuts (optional)
# ============================================================================

func _input(event):
	# Press F9 to test start recording
	if event.is_action_pressed("ui_page_up"):
		auto_record_start("test_recording")
	
	# Press F10 to test stop recording (3 second delay)
	if event.is_action_pressed("ui_page_down"):
		await auto_record_stop(3.0)


