#define DEFAULT_FREEZE_RADIUS 300.0
#define DEFAULT_FREEZE_TIME   10
#define BEEP_SOUND	      "weapons/hegrenade/beep.wav"

int	   iColorBlue[4]		  = { 0, 128, 255, 192 };

Handle	   g_hFreezeTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
int	   g_iFreezeBombTicks[MAXPLAYERS + 1];

/**
 * Sets or removes a freeze bomb on a player
 *
 * @param target        Target player index
 * @param ticks         Number of ticks before explosion (default: 8)
 * @param radius        Explosion radius (default: 300.0)
 * @param freezeTime    Time in seconds to freeze players (default: 10)
 * @return             True if bomb was set, false if removed or not a valid alive client
 */
stock bool SetPlayerFreezeBomb(int target, int ticks = 8, float radius = DEFAULT_FREEZE_RADIUS, int freezeTime = DEFAULT_FREEZE_TIME)
{
	// Validate target
	if (!IsValidAliveClient(target))
		return false;

	// If timer exists, kill it
	if (g_hFreezeTimer[target] != INVALID_HANDLE)
	{
		KillTimer(g_hFreezeTimer[target]);
		g_hFreezeTimer[target]	   = INVALID_HANDLE;
		g_iFreezeBombTicks[target] = 0;

		// Reset player color
		SetEntityRenderColor(target, 255, 255, 255, 255);

		return false;
	}

	// Set up new timer
	g_iFreezeBombTicks[target] = ticks;
	DataPack pack		   = new DataPack();
	pack.WriteCell(target);
	pack.WriteCell(ticks);
	pack.WriteFloat(radius);
	pack.WriteCell(freezeTime);

	g_hFreezeTimer[target] = CreateTimer(1.0, Timer_FreezeBomb, pack, REPEAT_TIMER);

	return true;
}

public Action Timer_FreezeBomb(Handle timer, DataPack pack)
{
	pack.Reset();
	int   target	 = pack.ReadCell();
	int   ticks	 = pack.ReadCell();
	float radius	 = pack.ReadFloat();
	int   freezeTime = pack.ReadCell();

	if (!IsValidAliveClient(target))
	{
		g_hFreezeTimer[target] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	g_iFreezeBombTicks[target]--;

	// Display countdown
	char targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, sizeof(targetName));
	PrintCenterTextAll("%t", "TankDraw_TimeToFreeze_NoColor", targetName, g_iFreezeBombTicks[target]);
	CPrintToChatAll("%t", "TankDraw_TimeToFreeze", targetName, g_iFreezeBombTicks[target]);

	if (g_iFreezeBombTicks[target] > 0)
	{
		// Visual and sound effects for countdown
		float vec[3];
		GetClientAbsOrigin(target, vec);
		vec[2] += 10;

		int color = RoundToFloor(g_iFreezeBombTicks[target] * (255.0 / ticks));
		SetEntityRenderColor(target, color, color, 255, 255);

		EmitSoundToAll(BEEP_SOUND, target);

		if (g_BeamSprite > -1 && g_HaloSprite > -1)
		{
			TE_SetupBeamRingPoint(vec, 10.0, radius * 1.5, g_BeamSprite, g_HaloSprite,
					      0, 10, 0.6, 15.0, 0.5, iColorBlue, 10, 0);
			TE_SendToAll();
		}

		return Plugin_Continue;
	}

	// Explosion effect
	float targetPos[3];
	GetClientAbsOrigin(target, targetPos);
	targetPos[2] += 10;

	EmitSoundToAll(FREEZE_SOUND, target);

	// Freeze all players within radius
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidAliveClient(i))
			continue;

		float playerPos[3];
		GetClientAbsOrigin(i, playerPos);

		if (GetVectorDistance(targetPos, playerPos) <= radius)
		{
			FreezePlayer(i, freezeTime);
		}
	}

	g_hFreezeTimer[target] = INVALID_HANDLE;
	return Plugin_Stop;
}

void FreezePlayer(int client, int duration)
{
	if (!IsValidAliveClient(client))
		return;

	// Clear existing timer if there is one
	if (g_hFreezeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFreezeTimer[client]);
		g_hFreezeTimer[client] = INVALID_HANDLE;
	}

	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, iColorBlue[0], iColorBlue[1], iColorBlue[2], iColorBlue[3]);

	g_hFreezeTimer[client] = CreateTimer(float(duration), Timer_Unfreeze, client, NO_REPEAT_TIMER);
}

public Action Timer_Unfreeze(Handle timer, any client)
{
	if (IsValidAliveClient(client))
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		EmitSoundToClient(client, FREEZE_SOUND);
	}
	g_hFreezeTimer[client] = INVALID_HANDLE;
	return Plugin_Stop;
}
stock void KillFreezeBomb(int client)
{
	if (g_hFreezeTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFreezeTimer[client]);
		g_hFreezeTimer[client]	   = INVALID_HANDLE;
		g_iFreezeBombTicks[client] = 0;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
}

stock void KillAllFreezeBombs()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillFreezeBomb(i);
	}
}