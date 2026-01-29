# Weapon Remover Plugin

**AMX Mod X plugin to remove weapons and items from the ground in Counter-Strike 1.6 maps, including dropped weapons.**

---

## Credits
- **ftl~**

---

## About

The **Weapon Remover** plugin allows administrators to control which weapons and items are allowed to remain on the ground in Counter-Strike 1.6 maps.  

Many maps contain weapons and items that spawn automatically or are dropped by players during gameplay. This plugin provides an easy way to remove unwanted items—either individually or globally—helping servers enforce specific gameplay rules and keep maps clean and organized.

It supports both **map-spawned items** and **player-dropped weapons**, with persistent configuration per map.

---

## Features

- **Individual Removal (Map Items)**  
  Remove specific weapons or items (e.g., `models/w_ak47.mdl`, `models/w_kevlar.mdl`) that spawn on the map.

- **Global Removal (REMOVE ALL)**  
  Remove all map-spawned weapons and items from the ground at once.

- **Individual Lock**  
  When `REMOVE ALL` is active, individual item options are disabled, with a chat message:  
  > *Global removal active. Changing individual item status is not allowed.*

- **Dropped Weapon Removal**  
  Automatically removes weapons dropped by players after a configurable delay.

- **Persistence**  
  Saves settings for map-spawned items in `.txt` files at:  
  `addons/amxmodx/configs/WeaponRemover/<mapname>.txt`  
  ensuring configurations persist across server restarts.

---

## Usage

### 1. Accessing the Menu (Map Items)
- As an admin with `ADMIN_IMMUNITY`, type:
  - `say /wremove`  
  - `say_team /wremove`
- The `[FWO] - Select Items:` menu will appear.

---

### 2. Menu Options (Map Items)

- **REMOVE ALL**  
  Toggles between:
  - `[ON]` → items are visible  
  - `[REMOVED]` → all ground items are removed

- **Individual Items**  
  Lists detected map items (e.g., `models/w_ak47.mdl`, `models/w_kevlar.mdl`).  
  Select an item to toggle between `[ON]` and `[REMOVED]`.

- When **REMOVE ALL** is `[REMOVED]`, individual options are disabled and display the message:  
  > *Global removal active. Changing individual item status is not allowed.*

---

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

- Weapons dropped by players (e.g., using the drop key, usually `G`) are automatically removed.
- Controlled by the following cvars:

- `wremove_drop_enable` (default: `1`)  
  Enables or disables dropped weapon removal.  
  Set to `0` to disable.

- `wremove_drop_time` (default: `10.0`)  
  Time in seconds before a dropped weapon is removed.

- Example:  
If `wremove_drop_time` is set to `5`, a dropped weapon will be removed 5 seconds after being dropped, unless picked up by another player.

---

## Restoration

- **Map Items**  
Disabling `REMOVE ALL` during the same session restores previous individual item states.  
After a map change, removed items only reappear when the map is reloaded.

- **Dropped Weapons**  
If `wremove_drop_enable` is set to `0`, dropped weapons will remain on the ground until picked up or the round ends.

---

## Contributions

Suggestions, improvements, and bug reports are welcome.  
Feel free to open an issue or submit a pull request.