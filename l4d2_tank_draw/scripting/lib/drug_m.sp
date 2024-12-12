// Global variables
Handle	   g_DrugTimers[MAXPLAYERS + 1]	  = { INVALID_HANDLE, ... };
Handle	   g_UndrugTimers[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
float	   g_DrugAngles[20]		  = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

// Exposed function to set a player in a drugged state for a specific duration
stock void SetDrug(int client, float seconds)
{
	if (!IsValidClient(client))
	{
		PrintToServer("[Tank Draw] Invalid client or client not in game.");
		return;
	}

	// If the client is already drugged, unset the drug immediately and return
	if (g_DrugTimers[client] != INVALID_HANDLE)
	{
		KillDrug(client);
		return;
	}

	// Start the drug effect immediately
	CreateDrug(client);

	// If an undrug timer already exists for this client, kill it
	if (g_UndrugTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_UndrugTimers[client]);
		g_UndrugTimers[client] = INVALID_HANDLE;
	}

	g_UndrugTimers[client] = CreateTimer(seconds, Timer_Undrug, client, NO_REPEAT_TIMER);
}

// Function to start the drug effect
void CreateDrug(int client)
{
	g_DrugTimers[client] = CreateTimer(1.0, Timer_Drug, client, REPEAT_TIMER);
}

// Function to stop the drug effect
void KillDrug(int client)
{
	KillDrugTimer(client);

	float angs[3];
	GetClientEyeAngles(client, angs);

	angs[2] = 0.0;

	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

	int clients[2];
	clients[0]	= client;

	int    duration = 1536;
	int    holdtime = 1536;
	int    flags	= (0x0001 | 0x0010);
	int    color[4] = { 0, 0, 0, 0 };

	Handle message	= StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, duration);
	BfWriteShort(message, holdtime);
	BfWriteShort(message, flags);
	BfWriteByte(message, color[0]);
	BfWriteByte(message, color[1]);
	BfWriteByte(message, color[2]);
	BfWriteByte(message, color[3]);
	EndMessage();
}

// Function to kill the drug timer
void KillDrugTimer(int client)
{
	if (g_DrugTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_DrugTimers[client]);
	}

	g_DrugTimers[client] = INVALID_HANDLE;
}

// Timer callback for the drug effect
public Action Timer_Drug(Handle timer, any client)
{
	if (!IsClientInGame(client))
	{
		KillDrugTimer(client);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(client))
	{
		KillDrug(client);
		return Plugin_Handled;
	}

	float angs[3];
	GetClientEyeAngles(client, angs);

	angs[2] = g_DrugAngles[GetRandomInt(0, 100) % 20];

	TeleportEntity(client, NULL_VECTOR, angs, NULL_VECTOR);

	int clients[2];
	clients[0]     = client;

	int duration   = 255;
	int holdtime   = 255;
	int flags      = 0x0002;
	int color[4]   = { 0, 0, 0, 128 };
	color[0]       = GetRandomInt(0, 255);
	color[1]       = GetRandomInt(0, 255);
	color[2]       = GetRandomInt(0, 255);

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	BfWriteShort(message, duration);
	BfWriteShort(message, holdtime);
	BfWriteShort(message, flags);
	BfWriteByte(message, color[0]);
	BfWriteByte(message, color[1]);
	BfWriteByte(message, color[2]);
	BfWriteByte(message, color[3]);
	EndMessage();

	return Plugin_Handled;
}

// Timer callback to stop the drug effect
public Action Timer_Undrug(Handle timer, any client)
{
	// Validate the client
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		g_UndrugTimers[client] = null;
		return Plugin_Handled;
	}

	// Stop the drug effect
	KillDrug(client);

	// Clear the timer handle
	g_UndrugTimers[client] = null;

	return Plugin_Handled;
}