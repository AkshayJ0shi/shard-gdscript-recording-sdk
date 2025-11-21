# RecordingSDK API Reference

Automatic game recording for Godot games. Communicate with an Electron recording app to capture gameplay moments.

---

## Installation

```bash
# Copy SDK to your project
cp -r recording-sdk/ your-project/addons/
```

```gdscript
# Add to your scene
var recording_sdk = RecordingSDK.new()
add_child(recording_sdk)
recording_sdk.connect_to_recorder()
```

---

## Core Functions

### `start_recording(event_id: String) -> String`

Start a new recording with an event identifier.

**Parameters:**
- `event_id` (String): Unique identifier for this clip (e.g., "boss_fight_ancient_dragon")

**Returns:**
- Recording ID (String) if successful, empty string if failed

**Example:**
```gdscript
var recording_id = await recording_sdk.start_recording("boss_fight_ancient_dragon")
```

**Note:** Electron will automatically add:
- `clip_id` - Auto-generated unique ID
- `game_name` - From Electron settings
- `event_name` - Resolved from `game_events.json` or `event_id`
- `clip_duration` - Calculated on stop
- `clip_name` - User input when saving
- `file_path` - Path to the saved video file
- `file_size` - Size of the video file

---

### `stop_recording(recording_id: String, delay_seconds: float = 0.0) -> void`

Stop an active recording with optional delay.

**Parameters:**
- `recording_id` - The ID returned from `start_recording()`
- `delay_seconds` - Optional delay before stopping (e.g., 3.0 for 3 seconds)

**Example:**
```gdscript
# Stop immediately
await recording_sdk.stop_recording(recording_id)

# Stop after 3 seconds
await recording_sdk.stop_recording(recording_id, 3.0)
```

---

### `connect_to_recorder() -> void`

Connect to the Electron recording application.

**Example:**
```gdscript
recording_sdk.connect_to_recorder()
```

---

### `disconnect_from_recorder() -> void`

Disconnect from the recording application.

**Example:**
```gdscript
recording_sdk.disconnect_from_recorder()
```

---

### `is_connected() -> bool`

Check if connected to the recorder.

**Returns:**
- `true` if connected, `false` otherwise

**Example:**
```gdscript
if recording_sdk.is_connected():
    print("Connected!")
```

---

### `is_auto_record_enabled() -> bool`

Check if auto-record is enabled by the user.

**Returns:**
- `true` if enabled, `false` otherwise

**Example:**
```gdscript
if recording_sdk.is_auto_record_enabled():
    # Start recording
    pass
```

---

## Signals

### `connected_to_recorder()`

Emitted when successfully connected to the Electron app.

**Example:**
```gdscript
recording_sdk.connected_to_recorder.connect(func():
    print("Connected!")
)
```

---

### `disconnected_from_recorder()`

Emitted when disconnected from the Electron app.

**Example:**
```gdscript
recording_sdk.disconnected_from_recorder.connect(func():
    print("Disconnected!")
)
```

---

### `recording_started(recording_id: String)`

Emitted when a recording starts.

**Example:**
```gdscript
recording_sdk.recording_started.connect(func(id):
    print("Recording started: ", id)
)
```

---

### `recording_stopped(recording_id: String, file_path: String)`

Emitted when a recording stops and is saved.

**Example:**
```gdscript
recording_sdk.recording_stopped.connect(func(id, path):
    print("Saved to: ", path)
)
```

---

### `auto_record_settings_changed(enabled: bool)`

Emitted when auto-record setting changes.

**Example:**
```gdscript
recording_sdk.auto_record_settings_changed.connect(func(enabled):
    print("Auto-record: ", "ON" if enabled else "OFF")
)
```

---

### `error_occurred(error_message: String)`

Emitted when an error occurs.

**Example:**
```gdscript
recording_sdk.error_occurred.connect(func(msg):
    print("Error: ", msg)
)
```

---

## Configuration

### Properties

```gdscript
var recording_sdk = RecordingSDK.new()

# WebSocket server URL (default: ws://localhost:9876)
recording_sdk.server_url = "ws://localhost:9876"

# Enable/disable auto-reconnect (default: true)
recording_sdk.auto_reconnect = true

# Reconnect delay in seconds (default: 2.0)
recording_sdk.reconnect_delay = 2.0

# Maximum reconnect attempts (default: 5)
recording_sdk.max_reconnect_attempts = 5
```

---

## Complete Example

### Boss Fight Recording

```gdscript
extends Node

var recording_sdk: RecordingSDK
var recording_id: String = ""

func _ready():
    recording_sdk = RecordingSDK.new()
    add_child(recording_sdk)
    recording_sdk.connect_to_recorder()

func on_boss_spawn():
    recording_id = await recording_sdk.start_recording("boss_fight_ancient_dragon")

func on_boss_defeated():
    # Stop recording 3 seconds after victory
    await recording_sdk.stop_recording(recording_id, 3.0)
    recording_id = ""
```

---

## Metadata Schema

### Required Fields

The SDK only sends the `event_id`. All other metadata is handled by the Electron launcher.

```gdscript
{
    "event_id": "unique_identifier"  # Required: Unique clip identifier
}
```

### Electron Auto-Generated Fields

When you save a clip, Electron automatically adds:

- `clip_id` - Auto-generated unique ID
- `game_name` - From Electron settings
- `event_name` - Resolved from `game_events.json` or `event_id`
- `clip_duration` - Calculated on stop
- `clip_name` - User input when saving to disk
- `file_path` - Path to the saved video file
- `file_size` - Size of the video file

---

## Requirements

- **Godot:** 4.0 or later
- **Electron App:** Must be running on `ws://localhost:9876`

---

## Troubleshooting

### "Not connected to recorder"

**Solution:** Ensure the Electron recording app is running.

```bash
# Check if port 9876 is open
netstat -an | grep 9876
```

---

### "Auto-record is disabled by user"

**Solution:** User needs to enable auto-record in the Electron app settings.

```gdscript
# Check programmatically
if not recording_sdk.is_auto_record_enabled():
    print("Please enable auto-record in the recorder app")
```

---

### Recording doesn't stop

**Solution:** Verify you're using the correct `recording_id`.

```gdscript
# Always store the recording ID
recording_id = await recording_sdk.start_recording(metadata)

# Use it to stop
await recording_sdk.stop_recording(recording_id)
```

---

## License

MIT License - Free to use in commercial and non-commercial projects.
