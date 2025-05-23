#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cromchat2>

#define PLUGIN "Weapon Remover"
#define AUTHOR "ftl~"
#define VERSION "1.0"

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

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_logevent("EventNewRound", 2, "1=Round_Start");
	register_logevent("EventNewRound", 2, "1=Round_End");

	register_clcmd("say /wremove", "OpenMainMenu", ADMIN_IMMUNITY);
	register_clcmd("say_team /wremove", "OpenMainMenu", ADMIN_IMMUNITY);

	cvar_auto_remove = register_cvar("wremove_auto_remove", "1");
	cvar_drop_enable = register_cvar("wremove_drop_enable", "1");
	cvar_drop_time = register_cvar("wremove_drop_time", "10.0");

	CC_SetPrefix("&x04[FWO]");

	if(!dir_exists(FILEPATH))
		mkdir(FILEPATH);
	
	g_Models = ArrayCreate(32, MAX_MODELS);
	g_Classnames = ArrayCreate(32, MAX_MODELS);
	g_ModelStatus = TrieCreate();
	g_TempStatus = TrieCreate();
	g_RemoveAll = false;
	
	register_forward(FM_SetModel, "Forward_SetModel");
	
	ScanMapItems();
	LoadMapConfig();
}

public plugin_cfg()
{
	register_dictionary("weapon_remover_ftl.txt");
}

public ScanMapItems()
{
	ArrayClear(g_Models);
	ArrayClear(g_Classnames);
	TrieClear(g_ModelStatus);
	TrieClear(g_TempStatus);
	
	new ent = -1, model[32], classname[32];
	while((ent = find_ent_by_class(ent, "armoury_entity")))
	{
		if(pev_valid(ent))
		{
			pev(ent, pev_model, model, charsmax(model));
			if(containi(model, "w_") == -1)
				continue;
			
			new temp[32];
			copy(temp, charsmax(temp), model[9]);
			temp[strlen(temp) - 4] = 0;
			formatex(classname, charsmax(classname), "weapon_%s", temp);
			
			if(ArrayFindString(g_Models, model) == -1)
			{
				ArrayPushString(g_Models, model);
				ArrayPushString(g_Classnames, classname);
				TrieSetCell(g_ModelStatus, model, false);
			}
		}
	}
}

public OpenMainMenu(id)
{
	if(!cmd_access(id, ADMIN_IMMUNITY, 0, 1))
		return PLUGIN_HANDLED;
	
	new title[64];
	formatex(title, charsmax(title), "\r[FWO] \d- \w%L", id, "MENU_MAIN_TITLE");
	new menu = menu_create(title, "MainMenuHandler");
	
	new itemText[64];
	formatex(itemText, charsmax(itemText), "\w%L", id, "MENU_MAP_WEAPONS");
	menu_additem(menu, itemText, "1");
	
	formatex(itemText, charsmax(itemText), "\w%L", id, "MENU_RESET_SETTINGS");
	menu_additem(menu, itemText, "2");
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL);
	menu_display(id, menu, 0);
	return PLUGIN_HANDLED;
}

public MainMenuHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu); 
		return PLUGIN_HANDLED;
	}
	
	switch(item)
	{
		case 0: ShowItemMenu(id);
		case 1: ResetMapConfig(id);
	}
	
	menu_destroy(menu);
	return PLUGIN_HANDLED;
}

public ShowItemMenu(id)
{
	if(!cmd_access(id, ADMIN_IMMUNITY, 0, 1))
		return PLUGIN_HANDLED;
	
	new title[64];
	formatex(title, charsmax(title), "\r[FWO] \d- \w%L", id, "MENU_SELECT_ITEMS");
	new menu = menu_create(title, "ShowItemHandler");
	
	new itemText[64], bool:status, model[32], classname[32];
	
	new statusText[32];
	formatex(statusText, charsmax(statusText), "\r%L", id, g_RemoveAll ? "STATUS_REMOVED" : "STATUS_ON");
	formatex(itemText, charsmax(itemText), "\r%L %s", id, "MENU_REMOVE_ALL", statusText);
	menu_additem(menu, itemText, "all");
	
	if(ArraySize(g_Models) == 0)
	{
		formatex(itemText, charsmax(itemText), "%L", id, "MENU_NO_ITEMS");
		menu_additem(menu, itemText, "", g_RemoveAll ? ITEM_DISABLED : 0);
	}
	else
	{
		for(new i = 0; i < ArraySize(g_Models); i++)
		{
			ArrayGetString(g_Models, i, model, charsmax(model));
			ArrayGetString(g_Classnames, i, classname, charsmax(classname));
			TrieGetCell(g_ModelStatus, model, status);
			
			new statusTextItem[32];
			formatex(statusTextItem, charsmax(statusTextItem), "\r%L", id, g_RemoveAll ? "STATUS_REMOVED" : (status ? "STATUS_REMOVED" : "STATUS_ON"));
			formatex(itemText, charsmax(itemText), "\w%s %s", classname, statusTextItem);
			menu_additem(menu, itemText, fmt("%d", i), g_RemoveAll ? ITEM_DISABLED : 0);
		}
	}
	
	menu_display(id, menu);
	return PLUGIN_HANDLED;
}

public ShowItemHandler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu);
		OpenMainMenu(id);
		return PLUGIN_HANDLED;
	}
	
	new info[8], dummy;
	menu_item_getinfo(menu, item, dummy, info, charsmax(info), _, _, dummy);
	
	if(equal(info, "all"))
	{
		if(!g_RemoveAll)
		{
			new model[32], bool:status;
			TrieClear(g_TempStatus);
			for(new i = 0; i < ArraySize(g_Models); i++)
			{
				ArrayGetString(g_Models, i, model, charsmax(model));
				TrieGetCell(g_ModelStatus, model, status);
				TrieSetCell(g_TempStatus, model, status);
			}
		}
		
		g_RemoveAll = !g_RemoveAll;
		
		if(!g_RemoveAll)
		{
			new model[32], bool:tempStatus;
			for(new i = 0; i < ArraySize(g_Models); i++)
			{
				ArrayGetString(g_Models, i, model, charsmax(model));
				if(TrieGetCell(g_TempStatus, model, tempStatus))
				{
					TrieSetCell(g_ModelStatus, model, tempStatus);
				}
				else
				{
					TrieSetCell(g_ModelStatus, model, false);
				}
			}
		}
		
		RemoveItems();
		SaveMapConfig();
	}
	else if(g_RemoveAll)
	{
		CC_SendMessage(id, "%L", id, "MSG_GLOBAL_ACTIVE");
		menu_destroy(menu);
		ShowItemMenu(id);
		return PLUGIN_HANDLED;
	}
	else
	{
		new index = str_to_num(info);
		new model[32];
		ArrayGetString(g_Models, index, model, charsmax(model));
		new bool:status;
		TrieGetCell(g_ModelStatus, model, status);
		TrieSetCell(g_ModelStatus, model, !status);
		
		RemoveItems();
		SaveMapConfig();
	}
	
	menu_destroy(menu);
	ShowItemMenu(id);
	return PLUGIN_HANDLED;
}

public ResetMapConfig(id)
{
	g_RemoveAll = false;
	TrieClear(g_ModelStatus);
	TrieClear(g_TempStatus);
	
	new map[32];
	get_mapname(map, charsmax(map));
	new filepath[256];
	formatex(filepath, charsmax(filepath), "%s/%s.txt", FILEPATH, map);
	if(file_exists(filepath))
	{
		delete_file(filepath);
	}
	
	ScanMapItems();
	CC_SendMessage(id, "%L", id, "MSG_SETTINGS_RESET");
	OpenMainMenu(id);
}

public EventNewRound()
{
	RemoveItems();
}

public LoadMapConfig()
{
	new mapFile[64], mapName[32];
	get_mapname(mapName, charsmax(mapName));
	formatex(mapFile, charsmax(mapFile), "%s/%s.txt", FILEPATH, mapName);
	
	g_RemoveAll = false;

	// Check if a config file exists
	new bool:hasConfig = (file_exists(mapFile) != 0);
	
	// If no config file exists and cvar is enabled, enable auto-remove initially
	if(!hasConfig && get_pcvar_num(cvar_auto_remove))
	{
		g_RemoveAll = true;
		new model[32];
		for(new i = 0; i < ArraySize(g_Models); i++)
		{
			ArrayGetString(g_Models, i, model, charsmax(model));
			TrieSetCell(g_ModelStatus, model, true);
		}
	}
	else
	{
		// If config file exists or cvar is disabled, load settings normally
		new model[32];
		for(new i = 0; i < ArraySize(g_Models); i++)
		{
			ArrayGetString(g_Models, i, model, charsmax(model));
			TrieSetCell(g_ModelStatus, model, false);
		}
		
		new file = fopen(mapFile, "r");
		if(file)
		{
			new line[32], model[32];
			while(!feof(file))
			{
				fgets(file, line, charsmax(line));
				trim(line);
				
				if(!line[0] || line[0] == ';')
					continue;
				
				parse(line, model, charsmax(model));
				trim(model);
				
				if(equal(model, "REMOVE_ALL"))
				{
					g_RemoveAll = true;
					for(new i = 0; i < ArraySize(g_Models); i++)
					{
						ArrayGetString(g_Models, i, model, charsmax(model));
						TrieSetCell(g_ModelStatus, model, true);
					}
				}
				else if(ArrayFindString(g_Models, model) != -1)
				{
					TrieSetCell(g_ModelStatus, model, true);
				}
			}
			fclose(file);
		}
	}
	
	RemoveItems();
}

public SaveMapConfig()
{
	new mapFile[64], mapName[32];
	get_mapname(mapName, charsmax(mapName));
	formatex(mapFile, charsmax(mapFile), "%s/%s.txt", FILEPATH, mapName);
	
	new file = fopen(mapFile, "wt");
	if(file)
	{
		if(g_RemoveAll)
		{
			fprintf(file, "REMOVE_ALL^n");
		}
		else
		{
			new model[32], bool:status;
			for(new i = 0; i < ArraySize(g_Models); i++)
			{
				ArrayGetString(g_Models, i, model, charsmax(model));
				TrieGetCell(g_ModelStatus, model, status);
				if(status)
					fprintf(file, "%s^n", model);
			}
		}
		fclose(file);
	}
}

public RemoveItems()
{
	new ent = -1, model[32], bool:status;
	while((ent = find_ent_by_class(ent, "armoury_entity")))
	{
		if(pev_valid(ent))
		{
			pev(ent, pev_model, model, charsmax(model));
			if(containi(model, "w_") != -1 && (g_RemoveAll || (TrieGetCell(g_ModelStatus, model, status) && status)))
			{
				remove_entity(ent);
			}
		}
	}
}

public Forward_SetModel(iEntity, const szModel[])
{
	if(!get_pcvar_num(cvar_drop_enable))
		return FMRES_IGNORED;

	static iOwner;
	iOwner = pev(iEntity, pev_owner);

	if(IsPlayer(iOwner) && task_exists(iEntity + REMOVE_TASK_ID))
	{
		remove_task(iEntity + REMOVE_TASK_ID);
	}

	if(IsPlayer(iOwner) && equal(szModel, "models/w_", 9))
	{
		static szClass[16];
		pev(iEntity, pev_classname, szClass, charsmax(szClass));

		static Float:iRemoveTime;
		iRemoveTime = get_pcvar_float(cvar_drop_time);

		if (equal(szClass, "weaponbox"))
		{
			set_task(iRemoveTime, "RemoveDroppedWeapon", iEntity + REMOVE_TASK_ID);
		}
	}

	return FMRES_IGNORED;
}

public RemoveDroppedWeapon(iTask)
{
	new iEntity = iTask - REMOVE_TASK_ID;
	if(!pev_valid(iEntity))
		return FMRES_IGNORED;

	static szClass[16];
	pev(iEntity, pev_classname, szClass, charsmax(szClass));

	if(equal(szClass, "weaponbox"))
		remove_entity(iEntity);
	return FMRES_IGNORED;
}