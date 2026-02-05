public OpenMainMenu(id)
{
	if(!cmd_access(id, ADMIN_IMMUNITY, 0, 1))
		return PLUGIN_HANDLED;
	
	new title[64];
	formatex(title, charsmax(title), "%L", id, "MENU_MAIN_TITLE", MENU_PREFIX);
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
	formatex(title, charsmax(title), "%L", id, "MENU_SELECT_ITEMS_TITLE", MENU_PREFIX);
	new menu = menu_create(title, "ShowItemHandler");
	
	new itemText[64], bool:status, model[32], classname[32];
	
	new statusText[32];
	formatex(statusText, charsmax(statusText), "\r%L", id, g_RemoveAll ? "MENU_STATUS_REMOVED" : "MENU_STATUS_ON");
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
			formatex(statusTextItem, charsmax(statusTextItem), "\r%L", id, g_RemoveAll ? "MENU_STATUS_REMOVED" : (status ? "MENU_STATUS_REMOVED" : "MENU_STATUS_ON"));
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
					TrieSetCell(g_ModelStatus, model, tempStatus);
				else
					TrieSetCell(g_ModelStatus, model, false);
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