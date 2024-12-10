#define DEFAULT_FREEZE_RADIUS 300.0
#define DEFAULT_FREEZE_TIME   10
#define BEEP_SOUND	      "weapons/hegrenade/beep.wav"

int	   iColorBlue[4] = { 0, 128, 255, 192 };

Handle	   g_hFreezeTimer[MAXPLAYERS + 1];
int	   g_iFreezeBombTicks[MAXPLAYERS + 1];
bool	   g_bIsFrozen[MAXPLAYERS + 1];

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
	if (g_hFreezeTimer[target] != null)
	{
		KillTimer(g_hFreezeTimer[target]);
		g_hFreezeTimer[target]	   = null;
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

	g_hFreezeTimer[target] = CreateTimer(1.0, Timer_FreezeBomb, pack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);

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
		g_hFreezeTimer[target] = null;
		return Plugin_Stop;
	}

	g_iFreezeBombTicks[target]--;

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

	if (g_ExplosionSprite > -1)
	{
		TE_SetupExplosion(targetPos, g_ExplosionSprite, 10.0, 1, 0, RoundToFloor(radius), 5000);
		TE_SendToAll();
	}

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

	g_hFreezeTimer[target] = null;
	return Plugin_Stop;
}

void FreezePlayer(int client, int duration)
{
	if (!IsValidAliveClient(client))
		return;

	g_bIsFrozen[client] = true;
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetEntityRenderColor(client, iColorBlue[0], iColorBlue[1], iColorBlue[2], iColorBlue[3]);

	// Create timer to unfreeze
	CreateTimer(float(duration), Timer_Unfreeze, client);
}

public Action Timer_Unfreeze(Handle timer, any client)
{
	if (IsValidAliveClient(client) && g_bIsFrozen[client])
	{
		g_bIsFrozen[client] = false;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		EmitSoundToClient(client, FREEZE_SOUND);
	}
	return Plugin_Stop;
}