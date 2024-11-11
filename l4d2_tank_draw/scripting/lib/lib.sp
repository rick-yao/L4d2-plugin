#define Z_TANK 8

// built-in convar
ConVar
	g_hInfinitePrimaryAmmo,
	g_MeleeRange,
	g_WorldGravity;

// Custom ConVars for the plugin
ConVar
	TankDrawEnable,
	ChanceNoPrice,
	ChanceIncreaseHealth,
	ChanceInfiniteAmmo,
	ChanceInfiniteMelee,
	ChanceLimitedTimeWorldMoonGravity,
	ChanceMoonGravityOneLimitedTime,
	ChanceAverageHealth,
	ChanceWorldMoonGravityToggle,
	ChanceIncreaseGravity,
	ChanceDecreaseHealth,
	ChanceKillAllSurvivor,
	ChanceKillSingleSurvivor,
	ChanceClearAllSurvivorHealth,
	ChanceDisarmAllSurvivor,
	ChanceDisarmSingleSurvivor,
	ChanceReviveAllDead,
	ChanceNewTank,

	ChanceDisarmSurvivorMolotov,
	ChanceKillSurvivorMolotov,

	SingleMoonGravity,
	LimitedTimeWorldMoonGravityTimer,
	InfiniteMeeleRange,
	L4D2TankDrawDebugMode,
	MinHealthIncrease,
	MaxHealthIncrease,
	MinHealthDecrease,
	MaxHealthDecrease,
	IncreasedGravity,
	WorldMoonGravity,
	LimitedTimeWorldMoonGravityOne,
	// timer bomb related
	ChanceTimerBomb,
	TimerBombRadius,
	TimerBombSecond,
	TimerBombRangeDamage;

Handle
	g_SingleGravityTimer[MAXPLAYERS + 1],
	g_WorldGravityTimer;

stock void CheatCommand(int client, const char[] sCommand, const char[] sArguments = "")
{
	static int iFlagBits, iCmdFlags;
	iFlagBits = GetUserFlagBits(client);
	iCmdFlags = GetCommandFlags(sCommand);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	SetCommandFlags(sCommand, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", sCommand, sArguments);
	SetUserFlagBits(client, iFlagBits);
	SetCommandFlags(sCommand, iCmdFlags);
}

stock bool IsPlayerIncapacitated(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

stock bool IsPlayerIncapacitatedAtAll(int client)
{
	return (IsPlayerIncapacitated(client) || IsHangingFromLedge(client));
}

stock bool IsHangingFromLedge(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1) == 1);
}

stock void DisarmPlayer(int client)
{
	for (int slot = 0; slot <= 4; slot++)
	{
		int weapon = GetPlayerWeaponSlot(client, slot);
		if (weapon != -1)
		{
			RemovePlayerItem(client, weapon);
			RemoveEntity(weapon);
		}
	}
}
stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

stock bool IsValidAliveClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2));
}

stock bool IsValidDeadClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && !IsPlayerAlive(client) && (GetClientTeam(client) == 2));
}

stock bool IsTank(int client)
{
	// Check if the client is valid and in-game
	if (!IsValidClient(client))
	{
		PrintToServer("[Tank Draw] IsTank: Client %d is not valid", client);
		return false;
	}

	// Check if the client is actually connected
	if (!IsClientConnected(client))
	{
		PrintToServer("[Tank Draw] IsTank: Client %d is not connected", client);
		return false;
	}

	// Check if the client is on the infected team
	if (GetClientTeam(client) != 3)	       // 3 is typically the infected team in L4D2
	{
		PrintToServer("[Tank Draw] IsTank: Client %d is not on the infected team (Team: %d)", client, GetClientTeam(client));
		return false;
	}
	if (!HasEntProp(client, Prop_Send, "m_zombieClass"))
	{
		return false;
	}

	PrintToServer("[Tank Draw] IsTank: Client %d passed all preliminary checks", client);
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

stock void PlaySoundToAll(const char[] sample)
{
	EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

stock bool TrySpawnTank(const float pos[3], int maxRetries = 3)
{
	int  attempts  = 1;
	bool IsSuccess = false;

	while (attempts <= maxRetries && !IsSuccess)
	{
		IsSuccess = L4D2_SpawnTank(pos, NULL_VECTOR) > 0;

		if (IsSuccess)
		{
			PrintToServer("[Tank Draw] Successfully spawned Tank at position: %.1f, %.1f, %.1f", pos[0], pos[1], pos[2]);
			PrintToServer("[Tank Draw] Successfully spawned Tank at %d attempts", attempts);
			return true;
		}

		attempts++;
	}

	PrintToServer("[Tank Draw] Failed to spawn Tank after %d attempts", maxRetries);
	return false;
}

stock void ResetAllTimer()
{
	KillAllTimeBombs();

	// reset single gravity timer
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_SingleGravityTimer[i])
		{
			delete g_SingleGravityTimer[i];
		}
	}

	// reset world gravity timer
	if (g_WorldGravityTimer)
	{
		delete g_WorldGravityTimer;
	}
}

stock Action ResetSingleGravity(Handle timer, int client)
{
	if (IsValidClient(client))
	{
		char clientName[MAX_NAME_LENGTH];
		GetClientName(client, clientName, sizeof(clientName));
		CPrintToChatAll("%t", "TankDraw_GravityResetSingle", clientName);
		PrintHintTextToAll("%t", "TankDraw_GravityResetSingle_NoColor", clientName);

		SetEntityGravity(client, 1.0);

		g_SingleGravityTimer[client] = null;
	}

	return Plugin_Continue;
}

stock Action ResetWorldGravity(Handle timer, int initValue)
{
	g_WorldGravity = FindConVar("sv_gravity");

	g_WorldGravity.RestoreDefault();

	CPrintToChatAll("%t", "TankDraw_WorldGravityReset");
	PrintHintTextToAll("%t", "TankDraw_WorldGravityReset_NoColor");

	g_WorldGravityTimer = null;

	return Plugin_Continue;
}

stock int GetTotalChance()
{
	int chanceNoPrice		      = ChanceNoPrice.IntValue;
	int chanceIncreaseHealth	      = ChanceIncreaseHealth.IntValue;
	int chanceInfiniteAmmo		      = ChanceInfiniteAmmo.IntValue;
	int chanceInfiniteMelee		      = ChanceInfiniteMelee.IntValue;
	int chanceAverageHealth		      = ChanceAverageHealth.IntValue;
	int chanceDecreaseHealth	      = ChanceDecreaseHealth.IntValue;
	int chanceKillAllSurvivor	      = ChanceKillAllSurvivor.IntValue;
	int chanceKillSingleSurvivor	      = ChanceKillSingleSurvivor.IntValue;
	int chanceDisarmAllSurvivor	      = ChanceDisarmAllSurvivor.IntValue;
	int chanceDisarmSingleSurvivor	      = ChanceDisarmSingleSurvivor.IntValue;
	int chanceNewTank		      = ChanceNewTank.IntValue;
	int chanceTimerBomb		      = ChanceTimerBomb.IntValue;

	int chanceLimitedTimeWorldMoonGravity = ChanceLimitedTimeWorldMoonGravity.IntValue;
	int chanceMoonGravityOneLimitedTime   = ChanceMoonGravityOneLimitedTime.IntValue;
	int chanceWorldMoonGravityToggle      = ChanceWorldMoonGravityToggle.IntValue;
	int chanceIncreaseGravity	      = ChanceIncreaseGravity.IntValue;
	int chanceClearAllSurvivorHealth      = ChanceClearAllSurvivorHealth.IntValue;
	int chanceReviveAllDead		      = ChanceReviveAllDead.IntValue;

	int totalChance			      = chanceNoPrice + chanceTimerBomb + chanceReviveAllDead + chanceNewTank + chanceDisarmSingleSurvivor + chanceDisarmAllSurvivor + chanceDecreaseHealth + chanceClearAllSurvivorHealth + chanceIncreaseHealth + chanceInfiniteAmmo + chanceInfiniteMelee + chanceAverageHealth + chanceKillAllSurvivor + chanceKillSingleSurvivor;
	totalChance += chanceLimitedTimeWorldMoonGravity + chanceMoonGravityOneLimitedTime + chanceWorldMoonGravityToggle + chanceIncreaseGravity;

	return totalChance;
}