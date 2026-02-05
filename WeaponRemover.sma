#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cromchat2>
#include <globals>
#include <menu>

#define PLUGIN "Weapon Remover"
#define AUTHOR "ftl~"
#define VERSION "1.0"

public plugin_init(){
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

public plugin_cfg(){
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

public EventNewRound(){
	RemoveItems();
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
					TrieSetCell(g_ModelStatus, model, true);
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
			fprintf(file, "REMOVE_ALL^n");
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
				remove_entity(ent);
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
		remove_task(iEntity + REMOVE_TASK_ID);

	if(IsPlayer(iOwner) && equal(szModel, "models/w_", 9))
	{
		static szClass[16];
		pev(iEntity, pev_classname, szClass, charsmax(szClass));

		static Float:iRemoveTime;
		iRemoveTime = get_pcvar_float(cvar_drop_time);

		if (equal(szClass, "weaponbox"))
			set_task(iRemoveTime, "RemoveDroppedWeapon", iEntity + REMOVE_TASK_ID);
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