# Demo System

The demo system records and replays gameplay as an **attract mode** on the title screen when the game is idle.

## Recording a Demo

1. Open the **Debug Save State Menu** (Cmd+S / Ctrl+S)
2. Press **[R]** to arm the recording
3. Close the menu and **select a stage** from the level select screen
4. Recording starts automatically when the player gains control
5. Play normally for up to **60 seconds** (3600 frames at 60fps)
6. Recording stops automatically after 60 seconds, or manually by reopening the Debug Menu (Cmd+S)

The demo file is saved to `user://demos/` as `demo_<LevelName>_<timestamp>.json`.

## Bundling Demos with the Game

Copy the recorded `.json` files from `user://demos/` into this `res://demos/` directory. On macOS the user directory is:

```
~/Library/Application Support/Godot/app_userdata/Mega Man X8 16-bit/demos/
```

Both `res://demos/` (bundled) and `user://demos/` (recorded) are scanned for available demos.

## Attract Mode Playback

- After **20 seconds** of idle on the intro or main menu screen, a demo plays automatically
- Demos play **sequentially** in discovery order without repeating until all have been shown
- Any **keyboard or gamepad input** cancels the demo and returns to the main menu
- Mouse input is ignored
- Smooth **fade transitions** (visual + music) are applied when entering and exiting a demo
- **Item drops are disabled** during both recording and playback to ensure deterministic replay

## Demo File Format

```json
{
  "version": 1,
  "level": "BoosterForest",
  "character": "X",
  "game_mode": 0,
  "collectibles": [],
  "equip_exceptions": [],
  "global_variables": {},
  "rng_seed": 0,
  "global_seed": 12345,
  "total_frames": 3600,
  "events": [
    [60, "move_right", true],
    [180, "jump", true],
    [195, "jump", false]
  ]
}
```

Each event is `[frame, action, pressed]`. A typical 60-second recording produces ~200-500 events.

## Tracked Actions

`move_right`, `move_left`, `move_up`, `move_down`, `jump`, `dash`, `fire`, `alt_fire`, `weapon_select_left`, `weapon_select_right`, `reset_weapon`, `select_special`, `pause`
