# RecordingSDK for Godot - README

## Overview

RecordingSDK is a GDScript library that allows your Godot game to communicate with an Electron-based recording application to automatically capture gameplay moments.

## Features

- ✅ Auto-recording triggered by game events
- ✅ Delayed stop (e.g., "stop 3 seconds after boss dies")
- ✅ Real-time metadata updates during recording
- ✅ Automatic reconnection on disconnect
- ✅ User-controlled auto-record toggle (in Electron app)
- ✅ Maximum recording duration (2 minutes default)

## Installation

### Option 1: Copy Files Directly

1. Copy the `recording-sdk` folder to your Godot project
2. The SDK will be available as `RecordingSDK` class

### Option 2: Use as Addon

1. Copy `recording-sdk` to `res://addons/recording-sdk/`
2. Enable the addon in Project Settings → Plugins

## Quick Start

### 1. Add SDK to Your Scene

```gdscript
extends Node

var recording_sdk: RecordingSDK

func _ready():
    # Create SDK instance
    recording_sdk = RecordingSDK.new()
    add_child(recording_sdk)
    
    # Connect to Electron app
    recording_sdk.connect_to_recorder()
```

### 2. Start Recording

```gdscript
# Start recording with a unique event identifier
var recording_id = await recording_sdk.start_recording("boss_fight_dragon")

# Store the ID for later
current_recording_id = recording_id
```

### 3. Stop Recording with Delay

```gdscript
# Stop recording 3 seconds after event completes
await recording_sdk.stop_recording(
    current_recording_id,
    3.0  # 3 second delay
)
```

### 4. Or Use Generic Helper Functions

```gdscript
# Start auto-recording
func auto_record_start(event_id: String):
    current_recording_id = await recording_sdk.start_recording(event_id)

# Stop auto-recording
func auto_record_stop(delay_seconds: float = 0.0):
    await recording_sdk.stop_recording(
        current_recording_id,
        delay_seconds
    )

# Usage
auto_record_start("speedrun_level_1")
# ... gameplay happens ...
await auto_record_stop(2.0)
```

## API Reference

### Methods

#### `connect_to_recorder() -> void`
Connect to the Electron recording application.

**Default URL**: `ws://localhost:9876`

```gdscript
recording_sdk.connect_to_recorder()
```

#### `disconnect_from_recorder() -> void`
Disconnect from the recorder.

```gdscript
recording_sdk.disconnect_from_recorder()
```

#### `start_recording(event_id: String) -> String`
Start a new recording with an event identifier.

**Parameters**:
- `event_id`: String - Unique identifier for this clip (e.g., "boss_fight_dragon")

**Returns**: Recording ID (String), or empty string if failed

**Example**:
```gdscript
var recording_id = await recording_sdk.start_recording("boss_fight_dragon")
```

#### `stop_recording(recording_id: String, delay_seconds: float = 0.0) -> void`
Stop an active recording.

**Parameters**:
- `recording_id`: The ID returned from `start_recording()`
- `delay_seconds`: Optional delay before stopping (e.g., 3.0 for 3 seconds)

**Example**:
```gdscript
# Stop immediately
await recording_sdk.stop_recording(recording_id)

# Stop after 3 seconds
await recording_sdk.stop_recording(recording_id, 3.0)
```

#### `request_settings() -> void`
Request current settings from the Electron app.

```gdscript
recording_sdk.request_settings()
```

#### `is_connected() -> bool`
Check if connected to the recorder.

```gdscript
if recording_sdk.is_connected():
    print("Connected!")
```

#### `is_auto_record_enabled() -> bool`
Check if auto-record is enabled by the user.

```gdscript
if recording_sdk.is_auto_record_enabled():
    print("Auto-record is ON")
```

#### `get_current_recording_id() -> String`
Get the current recording ID (empty if not recording).

```gdscript
var id = recording_sdk.get_current_recording_id()
```

### Signals

#### `connected_to_recorder()`
Emitted when successfully connected to the Electron app.

```gdscript
recording_sdk.connected_to_recorder.connect(func():
    print("Connected!")
)
```

#### `disconnected_from_recorder()`
Emitted when disconnected from the Electron app.

```gdscript
recording_sdk.disconnected_from_recorder.connect(func():
    print("Disconnected!")
)
```

#### `recording_started(recording_id: String)`
Emitted when a recording starts.

```gdscript
recording_sdk.recording_started.connect(func(id):
    print("Recording started: ", id)
)
```

#### `recording_stopped(recording_id: String, file_path: String)`
Emitted when a recording stops and is saved.

```gdscript
recording_sdk.recording_stopped.connect(func(id, path):
    print("Saved to: ", path)
)
```

#### `auto_record_settings_changed(enabled: bool)`
Emitted when auto-record setting changes in the Electron app.

```gdscript
recording_sdk.auto_record_settings_changed.connect(func(enabled):
    print("Auto-record: ", "ON" if enabled else "OFF")
)
```

#### `error_occurred(error_message: String)`
Emitted when an error occurs.

```gdscript
recording_sdk.error_occurred.connect(func(msg):
    print("Error: ", msg)
)
```

### Configuration

You can customize the SDK behavior:

```gdscript
var recording_sdk = RecordingSDK.new()

# Change server URL
recording_sdk.server_url = "ws://localhost:9999"

# Disable auto-reconnect
recording_sdk.auto_reconnect = false

# Change reconnect delay
recording_sdk.reconnect_delay = 5.0  # 5 seconds

# Change max reconnect attempts
recording_sdk.max_reconnect_attempts = 10
```

## Complete Example

```gdscript
extends Node

var recording_sdk: RecordingSDK
var current_recording_id: String = ""

func _ready():
    # Initialize SDK
    recording_sdk = RecordingSDK.new()
    add_child(recording_sdk)
    
    # Connect signals
    recording_sdk.recording_started.connect(_on_recording_started)
    recording_sdk.recording_stopped.connect(_on_recording_stopped)
    
    # Connect to recorder
    recording_sdk.connect_to_recorder()

# Player enters dungeon
func _on_player_enter_dungeon(dungeon_name: String):
    current_recording_id = await recording_sdk.start_recording("dungeon_entered")

# Boss defeated
func _on_boss_defeated(boss_name: String):
    if current_recording_id.is_empty():
        return
    
    # Stop recording 3 seconds after boss dies
    await recording_sdk.stop_recording(
        current_recording_id,
        3.0
    )
    
    current_recording_id = ""

func _on_recording_started(recording_id: String):
    print("✓ Recording started: ", recording_id)

func _on_recording_stopped(recording_id: String, file_path: String):
    print("✓ Saved: ", file_path)
```

## Metadata Best Practices

### Event Identifier
Always include an `event_id` to identify the clip:

```gdscript
# Recommended
await recording_sdk.start_recording("boss_fight_dragon")
```

### Recommended IDs
- `boss_fight_dragon`
- `speedrun_level_1`
- `achievement_first_blood`
- `pvp_deathmatch`

### Size Limits
- Keep event IDs under 255 characters
- Use filesystem-safe characters (alphanumeric, underscores, hyphens)

## Troubleshooting

### "Not connected to recorder"
- Ensure the Electron app is running
- Check that it's listening on `ws://localhost:9876`
- Verify firewall settings

### "Auto-record is disabled by user"
- User has disabled auto-record in the Electron app settings
- The SDK will still connect but won't start recordings

### Recording doesn't stop
- Check that you're using the correct `recording_id`
- Ensure the Electron app is still running
- Check the Electron app logs for errors

## Requirements

- Godot 4.0+
- Electron recording application running on `localhost:9876`

## License

MIT License - See LICENSE file for details
