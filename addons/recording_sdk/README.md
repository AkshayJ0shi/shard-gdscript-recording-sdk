# RecordingSDK for Godot 3.x

Automatically record gameplay moments by communicating with the Shard Recording application.

## Installation

1. Copy the `addons/recording_sdk` folder to your project's `addons/` directory
2. Enable the plugin in **Project > Project Settings > Plugins**
3. The SDK will automatically register as an autoload singleton

## Configuration

After enabling the plugin, configure it in **Project > Project Settings** under the `Recording SDK` section:

| Setting | Default | Description |
|---------|---------|-------------|
| Server URL | `ws://localhost:9876` | WebSocket URL of the recording server |
| Auto Connect | `true` | Connect automatically when game starts |
| Auto Reconnect | `true` | Reconnect if connection is lost |
| Reconnect Delay | `2.0` | Seconds between reconnection attempts |
| Max Reconnect Attempts | `5` | Maximum reconnection attempts before giving up |
| Enable Debug Logging | `false` | Print verbose debug messages |

## Usage

The SDK is available globally as `RecordingSDK` after enabling the plugin.

### Basic Recording

```gdscript
# Start recording when something interesting happens
func _on_boss_fight_started():
    var recording_id = yield(RecordingSDK.start_recording("boss_fight"), "completed")
    # Store recording_id to stop later

# Stop recording after the moment
func _on_boss_defeated():
    # Stop with 3 second delay to capture the aftermath
    yield(RecordingSDK.stop_recording(recording_id, 3.0), "completed")
```

### Signals

Connect to these signals to react to recording events:

```gdscript
func _ready():
    RecordingSDK.connect("connected_to_recorder", self, "_on_recorder_connected")
    RecordingSDK.connect("recording_started", self, "_on_recording_started")
    RecordingSDK.connect("recording_stopped", self, "_on_recording_stopped")
    RecordingSDK.connect("error_occurred", self, "_on_recording_error")

func _on_recorder_connected():
    print("Ready to record!")

func _on_recording_started(recording_id: String):
    print("Recording: ", recording_id)

func _on_recording_stopped(recording_id: String, file_path: String):
    print("Saved to: ", file_path)

func _on_recording_error(message: String):
    print("Error: ", message)
```

### Available Signals

| Signal | Parameters | Description |
|--------|------------|-------------|
| `connected_to_recorder` | - | Connected to recording server |
| `disconnected_from_recorder` | - | Disconnected from server |
| `recording_started` | `recording_id: String` | Recording has started |
| `recording_stopped` | `recording_id: String, file_path: String` | Recording saved |
| `auto_record_settings_changed` | `enabled: bool` | User toggled auto-record |
| `error_occurred` | `message: String` | An error occurred |

### API Reference

| Method | Returns | Description |
|--------|---------|-------------|
| `connect_to_recorder()` | `void` | Connect to the recording server |
| `disconnect_from_recorder()` | `void` | Disconnect from server |
| `start_recording(event_id)` | `String` (yield) | Start recording, returns recording ID |
| `stop_recording(id, delay)` | `void` (yield) | Stop recording with optional delay |
| `is_connected()` | `bool` | Check if connected |
| `is_recording()` | `bool` | Check if currently recording |
| `is_auto_record_enabled()` | `bool` | Check user's auto-record preference |
| `get_current_recording_id()` | `String` | Get active recording ID |
| `reload_settings()` | `void` | Reload settings from ProjectSettings |

## Event IDs

Use descriptive event IDs to categorize your recordings:

```gdscript
RecordingSDK.start_recording("boss_defeated_dragon")
RecordingSDK.start_recording("achievement_unlocked_speedrun")
RecordingSDK.start_recording("player_death_lava")
RecordingSDK.start_recording("secret_found_hidden_room")
```

## License

MIT License - Shard Games
