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
	ChanceNewWitch,
	ChanceDisableGlow,

	ChanceDisarmSurvivorMolotov,
	ChanceKillSurvivorMolotov,
	ChanceTimerBombMolotov,

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
	TimerBombRangeDamage,

	ChanceFreezeBomb,
	FreezeBombDuration,
	FreezeBombCountDown,
	FreezeBombRadius;

Handle g_SingleGravityTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle g_WorldGravityTimer		    = INVALID_HANDLE;

int    g_GlowDisabled			    = 0;

#define REPEAT_TIMER	TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE
#define NO_REPEAT_TIMER TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE

stock void ResetAllTimer()
{
	KillAllTimeBombs();
	KillAllFreezeBombs();

	// reset single gravity timer
	KillAllSingleGravityTimer();

	// reset world gravity timer
	if (g_WorldGravityTimer)
	{
		delete g_WorldGravityTimer
	}
}

stock void ResetAllValue()
{
	// reset all changed server value
	g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_ammo");
	g_hInfinitePrimaryAmmo.RestoreDefault();

	g_MeleeRange = FindConVar("melee_range");
	g_MeleeRange.RestoreDefault();

	g_WorldGravity = FindConVar("sv_gravity");
	g_WorldGravity.RestoreDefault();

	g_GlowDisabled = 0;
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

stock void OnSpawnComplete(bool success, int attempts)
{
	if (success)
	{
		CPrintToChatAll("%t", "Tank_NewTankSuccess");
	}
	else
	{
		CPrintToChatAll("%t", "Tank_NewTankFailed");
	}
}

stock void KillSingleGravityTimer(int client)
{
	if (g_SingleGravityTimer[client] != null)
	{
		KillTimer(g_SingleGravityTimer[client]);
		g_SingleGravityTimer[client] = null;
	}
}

stock void KillAllSingleGravityTimer()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		KillSingleGravityTimer(i);
	}
}

stock void ResetClient(int client)
{
	KillSingleGravityTimer(client);

	KillTimeBomb(client);

	KillFreezeBomb(client);

	SetEntityGravity(client, 1.0);

	SetEntityRenderColor(client, 255, 255, 255, 255);

	SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 1);
}
