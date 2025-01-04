
// Exposed function to set a player in a drugged state for a specific duration
stock void SetDrug(int client, int ticks = 30)
{
	if (!IsValidAliveClient(client))
	{
		DebugPrint("IsValidAliveClient false.");
		return;
	}

	// If the client is already drugged, unset the drug immediately and return
	if (g_hDrugTimers[client] != null)
	{
		delete g_hDrugTimers[client];
		g_iDrugTicks[client] = 0;
		ClearDrugState(client);
		return;
	}

	// Start the drug effect immediately
	g_iDrugTicks[client]  = ticks;
	g_hDrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, REPEAT_TIMER);
}

Action Timer_Drug(Handle timer, int client)
{
	if (!IsValidAliveClient(client))
	{
		delete g_hDrugTimers[client];
		g_iDrugTicks[client] = 0;
		return Plugin_Stop;
	}

	g_iDrugTicks[client]--;
	if (g_iDrugTicks[client] > 0)
	{
		float angs[3];
		GetClientEyeAngles(client, angs);

		angs[2] = g_fDrugAngles[GetRandomInt(0, 100) % 20];

		TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

		int clients[2];
		clients[0]   = client;

		int duration = 255;
		int holdtime = 255;
		int flags    = 0x0002;
		int color[4] = { 0, 0, 0, 128 };
		color[0]     = GetRandomInt(0, 255);
		color[1]     = GetRandomInt(0, 255);
		color[2]     = GetRandomInt(0, 255);
		SetEntityRenderColor(client, color[0], color[1], color[2], color[3]);

		Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
		BfWriteShort(message, duration);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, color[0]);
		BfWriteByte(message, color[1]);
		BfWriteByte(message, color[2]);
		BfWriteByte(message, color[3]);
		EndMessage();
	}
	if (g_iDrugTicks[client] == 0)
	{
		ClearDrugState(client);
		g_hDrugTimers[client] = null;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void ClearDrugState(int client)
{
	float angs[3];
	GetClientEyeAngles(client, angs);

	angs[2] = 0.0;

	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

	int clients[2];
	clients[0]   = client;

	int duration = 1536;
	int holdtime = 1536;
	int flags    = (0x0001 | 0x0010);
	int color[4] = { 0, 0, 0, 0 };
	SetEntityRenderColor(client, 255, 255, 255, 255);

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, duration);
	BfWriteShort(message, holdtime);
	BfWriteShort(message, flags);
	BfWriteByte(message, color[0]);
	BfWriteByte(message, color[1]);
	BfWriteByte(message, color[2]);
	BfWriteByte(message, color[3]);
	EndMessage();
}