// built-in convar
ConVar
	g_hInfiniteAmmo,
	g_hInfinitePrimaryAmmo,
	g_MeleeRange,
	g_WorldGravity;

// Custom ConVars for the plugin
ConVar
	TankDrawEnable,
	ChanceNoPrize,
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
	FreezeBombRadius,

	ChanceResetAllSurvivorHealth,

	ChanceInfinitePrimaryAmmo,

	DrugAllSurvivorChance,
	DrugAllSurvivorDuration,
	DrugLuckySurvivorChance,
	DrugLuckySurvivorDuration;

Handle g_SingleGravityTimer[MAXPLAYERS + 1] = { INVALID_HANDLE, ... };
Handle g_WorldGravityTimer		    = INVALID_HANDLE;

Handle g_hDrugTimers[MAXPLAYERS + 1];
int    g_iDrugTicks[MAXPLAYERS + 1];
float  g_fDrugAngles[20] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

int    g_GlowDisabled	 = 0;

#define REPEAT_TIMER	TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
#define NO_REPEAT_TIMER TIMER_FLAG_NO_MAPCHANGE

stock void ResetAllTimer()
{
	KillAllTimeBombs();
	KillAllFreezeBombs();

	// reset single gravity timer
	KillAllSingleGravityTimer();

	// reset world gravity timer
	if (g_WorldGravityTimer != INVALID_HANDLE)
	{
		KillTimer(g_WorldGravityTimer);
		g_WorldGravityTimer = INVALID_HANDLE;
	}
}

stock void ResetAllValue()
{
	// reset all changed server value
	g_hInfiniteAmmo = FindConVar("sv_infinite_ammo");
	g_hInfiniteAmmo.RestoreDefault();

	g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_primary_ammo");
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
	}

	g_SingleGravityTimer[client] = INVALID_HANDLE;
	return Plugin_Continue;
}

stock Action ResetWorldGravity(Handle timer, int initValue)
{
	g_WorldGravity = FindConVar("sv_gravity");

	g_WorldGravity.RestoreDefault();

	CPrintToChatAll("%t", "TankDraw_WorldGravityReset");
	PrintHintTextToAll("%t", "TankDraw_WorldGravityReset_NoColor");

	g_WorldGravityTimer = INVALID_HANDLE;

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
	if (g_SingleGravityTimer[client] != INVALID_HANDLE)
	{
		KillTimer(g_SingleGravityTimer[client]);
		g_SingleGravityTimer[client] = INVALID_HANDLE;
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
	delete g_hDrugTimers[client];
	g_iDrugTicks[client] = 0;

	KillSingleGravityTimer(client);

	KillTimeBomb(client);

	KillFreezeBombTimer(client);

	SetEntityGravity(client, 1.0);

	SetEntityRenderColor(client, 255, 255, 255, 255);

	SetEntProp(client, Prop_Send, "m_bSurvivorGlowEnabled", 1);
}
