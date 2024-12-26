int g_iClearBuffIfMissionLost;

// built-in convar
ConVar
	g_hInfiniteAmmo,
	g_hInfinitePrimaryAmmo,
	g_hMeleeRange,
	g_hWorldGravity;

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
	DrugLuckySurvivorDuration,
	ClearBuffIfMissionLost;

Handle g_SingleGravityTimer[MAXPLAYERS + 1];
Handle g_WorldGravityTimer;

Handle g_hDrugTimers[MAXPLAYERS + 1];
int    g_iDrugTicks[MAXPLAYERS + 1];
float  g_fDrugAngles[20] = { 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 20.0, 15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0, -20.0, -25.0, -20.0, -15.0, -10.0, -5.0 };

Handle g_hTimeBombTimer[MAXPLAYERS + 1];
int    g_iTimeBombTicks[MAXPLAYERS + 1];

Handle g_hFreezeBombTimer[MAXPLAYERS + 1];
Handle g_hUnfreezeTimer[MAXPLAYERS + 1];
int    g_iFreezeBombTicks[MAXPLAYERS + 1];

int    g_GlowDisabled = 0;

#define REPEAT_TIMER	TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE
#define NO_REPEAT_TIMER TIMER_FLAG_NO_MAPCHANGE
#define BEEP_SOUND	"weapons/hegrenade/beep.wav"
#define EXPLODE_SOUND	"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"
#define FREEZE_SOUND	"physics/glass/glass_impact_bullet4.wav"

stock void ResetAllTimer()
{
	KillAllTimeBombs();
	KillAllFreezeBombs();

	// reset single gravity timer
	KillAllSingleGravityTimer();

	// reset world gravity timer
	if (g_WorldGravityTimer != null)
	{
		delete g_WorldGravityTimer;
	}
}

stock void ResetAllValue()
{
	// reset all changed server value
	g_hInfiniteAmmo = FindConVar("sv_infinite_ammo");
	g_hInfiniteAmmo.RestoreDefault();

	g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_primary_ammo");
	g_hInfinitePrimaryAmmo.RestoreDefault();

	g_hMeleeRange = FindConVar("melee_range");
	g_hMeleeRange.RestoreDefault();

	g_hWorldGravity = FindConVar("sv_gravity");
	g_hWorldGravity.RestoreDefault();

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

	g_SingleGravityTimer[client] = null;
	return Plugin_Continue;
}

stock Action ResetWorldGravity(Handle timer, int initValue)
{
	g_hWorldGravity = FindConVar("sv_gravity");

	g_hWorldGravity.RestoreDefault();

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
		delete g_SingleGravityTimer[client];
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
