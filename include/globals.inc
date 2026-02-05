#define MENU_PREFIX "\r[FWO] \d-\w" 

#define FILEPATH "addons/amxmodx/configs/WeaponRemover"
#define MAX_PLAYERS 32
#define IsPlayer(%1) (1 <= %1 <= MAX_PLAYERS)
#pragma semicolon 1

const MAX_MODELS = 50;
const REMOVE_TASK_ID = 4096;

new Array:g_Models;
new Array:g_Classnames;
new Trie:g_ModelStatus;
new Trie:g_TempStatus;
new bool:g_RemoveAll;
new cvar_auto_remove;
new cvar_drop_enable;
new cvar_drop_time;