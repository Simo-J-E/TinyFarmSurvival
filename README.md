# Tiny Farm Survival (Godot 4)

A small 2D survival game using the included Kenney Tiny Farm graphics.

## Import
1. Extract the ZIP.
2. Open Godot 4.
3. Click **Import**.
4. Select `project.godot`.
5. Run the project.

## Menu and difficulty
The game now starts on a proper main menu. Choose one of three difficulty modes before starting:

- **Easy**: 130 HP, slower enemies, lower damage, slower spawning.
- **Normal**: 100 HP and balanced default values.
- **Hard**: 80 HP, faster enemies, more damage, faster spawning and scaling.

Press **Esc** during a run to return to the main menu.

## Controls
- WASD / Arrow keys: move
- Mouse: aim
- Hold left mouse button: fire bow and arrows

## Game loop
- Farm monsters continuously spawn around the map.
- They chase and damage the player.
- Spawn rate and monster strength increase over time.
- Each monster killed adds 1 to the kill score.
- When the player dies, the game shows kills, survival time and difficulty.
- Play again, return to the main menu, or quit.

## Graphics
Kenney Tiny Farm assets are included under `assets/tiny_farm/`.
License: CC0 (see `assets/tiny_farm/License.txt`).
