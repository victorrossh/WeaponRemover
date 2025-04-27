#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cromchat2>

#define PLUGIN "Weapon Remover"
#define AUTHOR "ftl~"
#define VERSION "1.0"

#define FILEPATH "addons/amxmodx/configs/WeaponRemover"
#pragma semicolon 1

const ADMIN_FLAG = ADMIN_IMMUNITY;
const MAX_MODELS = 50;

new Array:g_ModelNames;
new Trie:g_ModelStatus;
new Trie:g_TempStatus;
new bool:g_RemoveAll;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");
	register_logevent("EventNewRound", 2, "1=Round_Start");
	register_logevent("EventNewRound", 2, "1=Round_End");
	
	register_clcmd("say /wremove", "OpenMainMenu", ADMIN_FLAG);
	register_clcmd("say_team /wremove", "OpenMainMenu", ADMIN_FLAG);

	CC_SetPrefix("&x04[FWO]");

	if(!dir_exists(FILEPATH))
		mkdir(FILEPATH);
	
	g_ModelNames = ArrayCreate(32, MAX_MODELS);
	g_ModelStatus = TrieCreate();
	g_TempStatus = TrieCreate();
	g_RemoveAll = false;
	
	ScanMapItems();
	LoadMapConfig();
}

public ScanMapItems()
{
	ArrayClear(g_ModelNames);
	TrieClear(g_ModelStatus);
	TrieClear(g_TempStatus);
	
	new ent = -1, model[32];
	while((ent = find_ent_by_class(ent, "armoury_entity")))
	{
		if(pev_valid(ent))
		{
			pev(ent, pev_model, model, charsmax(model));
			if(containi(model, "w_") == -1)
				continue;
			
			if(ArrayFindString(g_ModelNames, model) == -1)
			{
				ArrayPushString(g_ModelNames, model);
				TrieSetCell(g_ModelStatus, model, false);
			}
		}
	}
}

public OpenMainMenu(id)
{
	if(!cmd_access(id, ADMIN_FLAG, 0, 1))
		return PLUGIN_HANDLED;
	
	new title[32];
	formatex(title, charsmax(title), "\r[FWO] \d- \wWeapon Remover");
	new menu = menu_create(title, "MainMenuHandler");
	
	menu_additem(menu, "\wMap Weapons", "1");
	menu_additem(menu, "\wReset All Settings", "2");
	
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
	if(!cmd_access(id, ADMIN_FLAG, 0, 1))
		return PLUGIN_HANDLED;
	
	new menu = menu_create("\r[FWO] \d- \wSelect Items:", "ShowItemHandler");
	new model[32], itemText[64], bool:status;
	
	formatex(itemText, charsmax(itemText), "\rREMOVE ALL %s", g_RemoveAll ? "\r[REMOVED]" : "\y[ON]");
	menu_additem(menu, itemText, "all");
	
	if(ArraySize(g_ModelNames) == 0)
		menu_additem(menu, "No items found in map", "", g_RemoveAll ? ITEM_DISABLED : 0);
	else
	{
		for(new i = 0; i < ArraySize(g_ModelNames); i++)
		{
			ArrayGetString(g_ModelNames, i, model, charsmax(model));
			TrieGetCell(g_ModelStatus, model, status);
			formatex(itemText, charsmax(itemText), "\w%s %s", model, g_RemoveAll ? "\r[REMOVED]" : (status ? "\r[REMOVED]" : "\y[ON]"));
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
			for(new i = 0; i < ArraySize(g_ModelNames); i++)
			{
				ArrayGetString(g_ModelNames, i, model, charsmax(model));
				TrieGetCell(g_ModelStatus, model, status);
				TrieSetCell(g_TempStatus, model, status);
			}
		}
		
		g_RemoveAll = !g_RemoveAll;
		
		if(!g_RemoveAll)
		{
			new model[32], bool:tempStatus;
			for(new i = 0; i < ArraySize(g_ModelNames); i++)
			{
				ArrayGetString(g_ModelNames, i, model, charsmax(model));
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
		CC_SendMessage(id, "Remoção global ativa. Alterar o status da entidade única não é permitido.");
		menu_destroy(menu);
		ShowItemMenu(id);
		return PLUGIN_HANDLED;
	}
	else
	{
		new index = str_to_num(info);
		new model[32];
		ArrayGetString(g_ModelNames, index, model, charsmax(model));
		new bool:status;
		TrieGetCell(g_ModelStatus, model, status);
		TrieSetCell(g_ModelStatus, model, !status);
		
		RemoveItems();
		SaveMapConfig();
	}
	
	menu_destroy(menu);
	ShowItemMenu(id)(id);
	return PLUGIN_HANDLED;
}

public ResetMapConfig(id)
{
	CC_SendMessage(id, "Not finished yet");
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
	new model[32];
	for(new i = 0; i < ArraySize(g_ModelNames); i++)
	{
		ArrayGetString(g_ModelNames, i, model, charsmax(model));
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
				for(new i = 0; i < ArraySize(g_ModelNames); i++)
				{
					ArrayGetString(g_ModelNames, i, model, charsmax(model));
					TrieSetCell(g_ModelStatus, model, true);
				}
			}
			else if(ArrayFindString(g_ModelNames, model) != -1)
			{
				TrieSetCell(g_ModelStatus, model, true);
			}
		}
		fclose(file);
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
			for(new i = 0; i < ArraySize(g_ModelNames); i++)
			{
				ArrayGetString(g_ModelNames, i, model, charsmax(model));
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