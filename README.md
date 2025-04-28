# Weapon Remover Plugin

**AMX Mod X plugin to remove weapons and items from the ground in Counter-Strike 1.6 maps, including dropped weapons.**

---

## About

This plugin was created for my Counter-Strike 1.6 surf server, where the rule is to allow only **M3**, **Desert Eagle**, and **HE Grenade**.  
In surf maps like `surf_style2_aks`, weapons and items (e.g., AK-47, vests, grenades) often spawn on the ground or are dropped by players, conflicting with the server's rules.  
The **Weapon Remover** plugin allows administrators to remove these items—both map-spawned and player-dropped—individually or globally, keeping the map clean and aligned with the intended gameplay.

---

## Features

- **Individual Removal (Map Items)**: Remove specific weapons or items (e.g., `models/w_ak47.mdl`, `models/w_kevlar.mdl`) that spawn on the map.
- **Global Removal (REMOVE ALL)**: Remove all map-spawned weapons and items from the ground at once.
- **Individual Lock**: When `REMOVE ALL` is active, individual item options are disabled, with a chat message:  
  > *Global removal active. Changing individual item status is not allowed.*
- **Dropped Weapon Removal**: Automatically remove weapons dropped by players.
- **Persistence**: Saves settings for map-spawned items in `.txt` files at `addons/amxmodx/configs/WeaponRemover/<mapname>.txt`, keeping customizations across server restarts.

---

## Usage

### 1. Accessing the Menu (Map Items)
- As an admin with `ADMIN_IMMUNITY`, type `say /wremove` or `say_team /wremove` in chat.
- The `[FWO] - Select Items:` menu will appear.

### 2. Menu Options (Map Items)
- **REMOVE ALL**: Toggles between `[ON]` (items visible) and `[REMOVED]` (removes all ground items).
- **Individual Items**: Lists map items (e.g., `models/w_ak47.mdl`, `models/w_kevlar.mdl`). Select to toggle between `[ON]` and `[REMOVED]`.
- When `REMOVE ALL` is `[REMOVED]`, individual options are grayed out with a message:  
  > *Global removal active. Changing individual item status is not allowed.*

### 3. Persistence (Map Items)
- Settings for map-spawned items are saved in `addons/amxmodx/configs/WeaponRemover/<mapname>.txt`.
- Example for `surf_style2_aks.txt`:
  - If **REMOVE ALL** is active:
    ```
    REMOVE_ALL
    ```
  - If specific items are removed:
    ```
    models/w_ak47.mdl
    models/w_kevlar.mdl
    ```

---

### 4. Dropped Weapon Removal
- The plugin automatically removes weapons dropped by players (e.g., when a player presses the drop key, usually `G`).
- Controlled by two cvars:
- `wremove_drop_enable` (default: `1`): Enables/disables the removal of dropped weapons. Set to `0` to disable.
- `wremove_drop_time` (default: `10.0`): Time in seconds before a dropped weapon is removed.
- Example: If `wremove_drop_time` is set to `5`, a dropped weapon will be removed 5 seconds after being dropped, unless picked up by another player.

---

## Restoration

- **Map Items**: Disabling `REMOVE ALL` in the same session restores previous item statuses (e.g., if `models/w_ak47.mdl` was `[ON]`, it becomes visible again). After a map change, removed items only reappear when the map is reloaded (e.g., using `amx_map surf_style2_aks`).
- **Dropped Weapons**: If `wremove_drop_enable` is set to `0`, dropped weapons will no longer be automatically removed and will remain on the ground until the round ends or they are picked up.

---

## Contributions

This plugin was developed for my surf server's specific needs.  
For suggestions, improvements, or bug reports, please contact me or submit a pull request.

**Author**: ftl~  
**Version**: 1.0