stock Action MenuFunc_MainMenu(int client, int args)
{
	Handle menu = CreateMenu(MenuHandler_MainMenu);
	char   line[1024];

	FormatEx(line, sizeof(line), "抽奖调试菜单 / tank draw debug menu");
	SetMenuTitle(menu, line);
	AddMenuItem(menu, "item0", "杀死tank / kill tank");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
		CloseHandle(menu);

	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0: MenuFunc_KillTank(client);
		}
	}
	return 0;
}

Action MenuFunc_KillTank(int client)
{
	Menu menu = CreateMenu(MenuHandler_KillTank);
	char line[1024];

	FormatEx(line, sizeof(line), "杀死tank / kill tank");
	SetMenuTitle(menu, line);

	char dis[1024];
	FormatEx(dis, sizeof(dis), "杀死所有tank / kill all tank");

	menu.AddItem("kill all tank", dis);
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

int MenuHandler_KillTank(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0:
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsTank(i))
					{
						SDKHooks_TakeDamage(i, i, client, 70000.0, DMG_BULLET, _, _, _, false);
					}
				}
			}
		}
	}
	return 0;
}
