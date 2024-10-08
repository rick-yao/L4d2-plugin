#pragma semicolon 1
#pragma newdecls required 1	   // force new syntax

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>

#define PLUGIN_VERSION "2.1.1"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

#define Z_TANK	       8

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
	ChanceLimitedTimeAllGodMode,
	ChanceLimitedTimeSingleGodMode,

	ChanceDisarmSurvivorMolotov,
	ChanceKillSurvivorMolotov,

	LimitedTimeSingleGodModeTimer,
	LimitedTimeAllGodModeTimer,
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
	LimitedTimeWorldMoonGravityOne;

Handle
	g_SingleGravityTimer[MAXPLAYERS],
	g_WorldGravityTimer,
	g_SingleGodModeTimer[MAXPLAYERS],
	g_AllGodModeTimer;

public Plugin myinfo =
{
	author	    = "Rick",
	name	    = "L4D2 Tank Draw",
	description = "Face your destiny after killing a tank",
	version	    = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	LoadTranslations("l4d2_tank_draw.phrases");

	TankDrawEnable			  = CreateConVar("l4d2_tank_draw_enable", "1", "Tank抽奖插件开/关 [1=开|0=关]。 / Tank draw plugin on/off [1=on|0=off].", PLUGIN_FLAG, true, 0.0, true, 1.0);
	L4D2TankDrawDebugMode		  = CreateConVar("l4d2_tank_draw_debug_mode", "0", "是否开启调试模式，修改后tank被击杀即可抽奖，使用!x开启击杀tank菜单 / Enable debug mode, draw after tank is killed when enabled, use !x open kill tank menu", false, false);

	// 单人限时重力 / Single player limited time gravity
	SingleMoonGravity		  = CreateConVar("l4d2_tank_draw_single_moon_gravity", "0.1", "单人月球重力参数，人物正常重力值为1 / Single player moon gravity parameter, normal gravity is 1", false, false);
	LimitedTimeWorldMoonGravityOne	  = CreateConVar("l4d2_tank_draw_limited_time_world_moon_gravity_one", "180", "单人限时月球重力持续秒数 / Duration in seconds for single player limited time moon gravity", false, false);
	ChanceMoonGravityOneLimitedTime	  = CreateConVar("l4d2_tank_draw_chance_moon_gravity_one_limited_time", "10", "抽奖者单人获得限时月球重力的概率 / Probability of single player getting limited time moon gravity", FCVAR_NONE);

	// 世界重力 / World gravity
	WorldMoonGravity		  = CreateConVar("l4d2_tank_draw_world_moon_gravity", "80", "月球重力时世界重力参数，世界重力正常值为800 / World gravity parameter for moon gravity, normal world gravity is 800", false, false);
	ChanceWorldMoonGravityToggle	  = CreateConVar("l4d2_tank_draw_chance_world_moon_gravity_toggle", "5", "世界重力切换为月球重力的概率 / Probability of toggling world gravity to moon gravity", FCVAR_NONE);

	// 世界限时月球重力 / World limited time moon gravity
	LimitedTimeWorldMoonGravityTimer  = CreateConVar("l4d2_tank_draw_limited_time_world_moon_gravity_timer", "180", "限时世界重力改为月球重力持续秒数 / Duration in seconds for limited time world moon gravity", false, false);
	ChanceLimitedTimeWorldMoonGravity = CreateConVar("l4d2_tank_draw_chance_limited_time_world_moon_gravity", "10", "获得限时世界重力改为月球重力的概率 / Probability of getting limited time world moon gravity", FCVAR_NONE);

	// 增加单人重力 / Increase single player gravity
	IncreasedGravity		  = CreateConVar("l4d2_tank_draw_increased_gravity", "2.0", "抽奖增加单人重力的倍数，从1.0至8.0 / Multiplier for increasing single player gravity, from 1.0 to 8.0", PLUGIN_FLAG, true, 1.0, true, 8.0);
	ChanceIncreaseGravity		  = CreateConVar("l4d2_tank_draw_chance_increase_gravity", "10", "增加单人重力的概率 / Probability of increasing single player gravity", FCVAR_NONE);

	InfiniteMeeleRange		  = CreateConVar("l4d2_tank_draw_infinite_melee_range", "700", "无限近战范围，游戏默认为70，重复抽取会自动恢复默认值 / Infinite melee range, game default is 70, repeated draws will restore default value", false, false);
	ChanceInfiniteMelee		  = CreateConVar("l4d2_tank_draw_chance_infinite_melee", "5", "无限近战范围的概率 / Probability of infinite melee range", FCVAR_NONE);
	ChanceIncreaseHealth		  = CreateConVar("l4d2_tank_draw_chance_increase_health", "10", "增加生命值的概率 / Probability of increasing health", FCVAR_NONE);
	MinHealthIncrease		  = CreateConVar("l4d2_tank_draw_min_health_increase", "200", "抽奖增加血量的最小值 / Minimum value for health increase", false, false);
	MaxHealthIncrease		  = CreateConVar("l4d2_tank_draw_max_health_increase", "500", "抽奖增加血量的最大值 / Maximum value for health increase", false, false);
	ChanceDecreaseHealth		  = CreateConVar("l4d2_tank_draw_chance_decrease_health", "10", "抽奖受到伤害的概率 / Probability of receiving damage", FCVAR_NONE);
	MinHealthDecrease		  = CreateConVar("l4d2_tank_draw_min_health_decrease", "200", "抽奖受到伤害的最小值 / Minimum value for health decrease", false, false);
	MaxHealthDecrease		  = CreateConVar("l4d2_tank_draw_max_health_decrease", "500", "抽奖受到伤害的最大值 / Maximum value for health decrease", false, false);
	ChanceNoPrice			  = CreateConVar("l4d2_tank_draw_chance_no_price", "20", "没有奖励的概率 / Probability of no reward", FCVAR_NONE);
	ChanceInfiniteAmmo		  = CreateConVar("l4d2_tank_draw_chance_infinite_ammo", "10", "无限弹药的概率 / Probability of infinite ammo", FCVAR_NONE);
	ChanceAverageHealth		  = CreateConVar("l4d2_tank_draw_chance_average_health", "10", "平均生命值的概率 / Probability of average health", FCVAR_NONE);
	ChanceKillAllSurvivor		  = CreateConVar("l4d2_tank_draw_chance_kill_all_survivor", "10", "团灭概率 / Probability of killing all survivors", FCVAR_NONE);
	ChanceKillSingleSurvivor	  = CreateConVar("l4d2_tank_draw_chance_kill_single_survivor", "10", "单人死亡概率 / Probability of killing a single survivor", FCVAR_NONE);
	ChanceClearAllSurvivorHealth	  = CreateConVar("l4d2_tank_draw_chance_clear_all_survivor_health", "10", "清空所有人血量概率 / Probability of clearing all survivors' health", FCVAR_NONE);
	ChanceDisarmAllSurvivor		  = CreateConVar("l4d2_tank_draw_chance_disarm_all_survivor", "10", "所有人缴械概率 / Probability of disarming all survivors", FCVAR_NONE);
	ChanceDisarmSingleSurvivor	  = CreateConVar("l4d2_tank_draw_chance_disarm_single_survivor", "10", "单人缴械概率 / Probability of disarming a single survivor", FCVAR_NONE);
	ChanceDisarmSurvivorMolotov	  = CreateConVar("l4d2_tank_draw_chance_disarm_survivor_molotov", "30", "无限弹药时，玩家乱扔火时缴械概率（百分比，0为关闭） / Probability of disarming a survivor when throwing molotovs recklessly with infinite ammo (percentage, 0 to disable)", FCVAR_NONE);
	ChanceKillSurvivorMolotov	  = CreateConVar("l4d2_tank_draw_chance_kill_survivor_molotov", "30", "无限弹药时，玩家乱扔火时处死概率（百分比，0为关闭） / Probability of killing a survivor when throwing molotovs recklessly with infinite ammo (percentage, 0 to disable)", FCVAR_NONE);

	// single god mode
	ChanceLimitedTimeSingleGodMode	  = CreateConVar("l4d2_tank_draw_chance_limited_time_single_god_mode", "30", "单人限时无敌概率 / Probability of single player god mode", FCVAR_NONE);
	LimitedTimeSingleGodModeTimer	  = CreateConVar("l4d2_tank_draw_limited_time_single_god_mode_timer", "180", "单人限时无敌持续秒数 / Duration in seconds of limited time single player god mode", false, false);
	// all god mode
	ChanceLimitedTimeAllGodMode	  = CreateConVar("l4d2_tank_draw_chance_limited_time_all_god_mode", "30", "全体限时无敌概率 / Probability of all player god mode", FCVAR_NONE);
	LimitedTimeAllGodModeTimer	  = CreateConVar("l4d2_tank_draw_limited_time_all_god_mode_timer", "180", "全体限时无敌持续秒数 / Duration in seconds of limited time all player god mode", false, false);

	AutoExecConfig(true, "l4d2_tank_draw");

	PrintToServer("[Tank Draw] Plugin loaded");
	PrintToServer("[Tank Draw] debug mode: %d", L4D2TankDrawDebugMode.IntValue);

	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_death", Event_PlayerDeath);

	HookEvent("molotov_thrown", Event_Molotov);

	HookEvent("finale_vehicle_leaving", Event_Roundend, EventHookMode_Pre);
	HookEvent("map_transition", Event_Roundend, EventHookMode_Pre);
	HookEvent("finale_win", Event_Roundend, EventHookMode_Pre);

	if (L4D2TankDrawDebugMode.IntValue == 1)
	{
		PrintToServer("调试菜单打开,debug menu on");
		RegConsoleCmd("sm_x", MenuFunc_MainMenu, "打开调试菜单 / open debug menu");
		HookEvent("tank_killed", Event_PlayerIncapacitated);
	}
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }
	// Check if the victim is a Tank
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!IsTank(victim))
	{
		PrintToServer("[Tank Draw] Victim is not a Tank. Exiting event.");
		return Plugin_Continue;
	}

	// if the victim is a tank, check if the weapon is a melee weapon
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (StrEqual(weapon, "melee", false) || L4D2TankDrawDebugMode.IntValue == 1)
	{
		// check if the attacker is an alive client
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (!IsValidAliveClient(attacker))
		{
			PrintToServer("[Tank Draw] Attacker %d is not a valid alive client. Exiting event.", attacker);
			return Plugin_Continue;
		}

		// now the attacker is a valid client and the weapon is a melee weapon
		// so we can make the tank draw
		PrintToServer("[Tank Draw] Event_PlayerDeath triggered. Victim: %d, Attacker: %d, weapon: %s", victim, attacker, weapon);

		char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
		GetClientName(victim, victimName, sizeof(victimName));
		GetClientName(attacker, attackerName, sizeof(attackerName));
		CPrintToChatAll("%t", "TankDraw_StartDraw", victimName, attackerName);

		// Lucky draw logic
		LuckyDraw(victim, attacker);

		CPrintToChatAll("%t", "TankDraw_DrawDone");
		return Plugin_Continue;
	}
	else {
		PrintToServer("[Tank Draw] No Melee weapon detected. Exiting event.");
		int  attacker = GetClientOfUserId(event.GetInt("attacker"));
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		if (!IsValidAliveClient(attacker))
		{
			CPrintToChatAll("%t", "TankDraw_NotKilledByHuman", attackerName);
			PrintHintTextToAll("%t", "TankDraw_NotKilledByHuman_NoColor", attackerName);
			PrintToServer("[Tank Draw] Attacker is not a valid alive client. Exiting event.");
			return Plugin_Continue;
		}

		CPrintToChatAll("%t", "TankDraw_NotByMelee", attackerName);
		PrintHintTextToAll("%t", "TankDraw_NotByMelee_NoColor", attackerName);
		return Plugin_Continue;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }
	// reset value when player died
	int victim = GetClientOfUserId(event.GetInt("userid"));
	PrintToServer("player dead... %d", victim);

	SetEntityGravity(victim, 1.0);

	return Plugin_Continue;
}

public Action Event_Roundend(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }
	// reset all timer
	ResetAllTimer();

	// reset all changed server value
	g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_ammo");
	g_hInfinitePrimaryAmmo.RestoreDefault();

	g_MeleeRange = FindConVar("melee_range");
	g_MeleeRange.RestoreDefault();

	g_WorldGravity = FindConVar("sv_gravity");
	g_WorldGravity.RestoreDefault();

	return Plugin_Continue;
}

public Action Event_Molotov(Event event, const char[] name, bool dontBroadcast)
{
	// randomly kill player when infinite ammo is active
	g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_ammo");
	if (g_hInfinitePrimaryAmmo.IntValue == 1)
	{
		int  random			 = GetRandomInt(1, 100);
		int  chanceDisarmSurvivorMolotov = ChanceDisarmSurvivorMolotov.IntValue;
		int  chanceKillSurvivorMolotov	 = ChanceKillSurvivorMolotov.IntValue;

		int  attacker			 = GetClientOfUserId(event.GetInt("userid"));
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		if (random <= chanceDisarmSurvivorMolotov)
		{
			DisarmPlayer(attacker);

			CPrintToChatAll("%t", "TankDraw_MolotovDisarmMsg", attackerName);
			PrintHintTextToAll("%t", "TankDraw_MolotovDisarmMsg_NoColor", attackerName);
			return Plugin_Continue;
		}
		if (random <= chanceDisarmSurvivorMolotov + chanceKillSurvivorMolotov)
		{
			ForcePlayerSuicide(attacker);

			CPrintToChatAll("%t", "TankDraw_MolotovDeathMsg", attackerName);
			PrintHintTextToAll("%t", "TankDraw_MolotovDeathMsg_NoColor", attackerName);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	if (TankDrawEnable.IntValue == 0) { return; }
	// reset all timer
	ResetAllTimer();

	// reset all changed server value
	g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_ammo");
	g_hInfinitePrimaryAmmo.RestoreDefault();

	g_MeleeRange = FindConVar("melee_range");
	g_MeleeRange.RestoreDefault();

	g_WorldGravity = FindConVar("sv_gravity");
	g_WorldGravity.RestoreDefault();
}

Action LuckyDraw(int victim, int attacker)
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
	int chanceLimitedTimeSingleGodMode    = ChanceLimitedTimeSingleGodMode.IntValue;
	int chanceLimitedTimeAllGodMode	      = ChanceLimitedTimeAllGodMode.IntValue;

	int chanceLimitedTimeWorldMoonGravity = ChanceLimitedTimeWorldMoonGravity.IntValue;
	int chanceMoonGravityOneLimitedTime   = ChanceMoonGravityOneLimitedTime.IntValue;
	int chanceWorldMoonGravityToggle      = ChanceWorldMoonGravityToggle.IntValue;
	int chanceIncreaseGravity	      = ChanceIncreaseGravity.IntValue;
	int chanceClearAllSurvivorHealth      = ChanceClearAllSurvivorHealth.IntValue;

	int totalChance			      = chanceNoPrice + chanceLimitedTimeSingleGodMode + chanceLimitedTimeAllGodMode + chanceDisarmSingleSurvivor + chanceDisarmAllSurvivor + chanceDecreaseHealth + chanceClearAllSurvivorHealth + chanceIncreaseHealth + chanceInfiniteAmmo + chanceInfiniteMelee + chanceAverageHealth + chanceKillAllSurvivor + chanceKillSingleSurvivor;
	totalChance += chanceLimitedTimeWorldMoonGravity + chanceMoonGravityOneLimitedTime + chanceWorldMoonGravityToggle + chanceIncreaseGravity;

	if (totalChance == 0)
	{
		PrintToServer("所有概率总和为0，跳过抽奖 / total change equals to 0, do not draw");
		return Plugin_Continue;
	}

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));

	int random = GetRandomInt(1, totalChance);
	PrintToServer("total chance: %d, random: %d", totalChance, random);

	int currentChance = 0;

	// no prize
	currentChance += chanceNoPrice;
	if (random <= currentChance)
	{
		CPrintToChatAll("%t", "TankDrawResult_NoPrize", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_NoPrize_NoColor", attackerName);

		return Plugin_Continue;
	}

	// limited time single god mode
	currentChance += chanceLimitedTimeSingleGodMode;
	if (random <= currentChance)
	{
		if (IsValidAliveClient(attacker))
		{
			EnableGodMode(attacker);
			if (g_SingleGodModeTimer[attacker])
			{
				delete g_SingleGodModeTimer[attacker];
			}
			g_SingleGodModeTimer[attacker] = CreateTimer(GetConVarFloat(LimitedTimeSingleGodModeTimer), DisableGodMode, attacker);

			CPrintToChatAll("%t", "TankDrawResult_SingleLimitedTimeGodMode", attackerName, GetConVarInt(LimitedTimeSingleGodModeTimer));
			PrintHintTextToAll("%t", "TankDrawResult_SingleLimitedTimeGodMode_NoColor", attackerName, GetConVarInt(LimitedTimeSingleGodModeTimer));
		}

		return Plugin_Continue;
	}

	// limited time all god mode
	currentChance += chanceLimitedTimeAllGodMode;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				EnableGodMode(i);
			}
		}
		if (g_AllGodModeTimer)
		{
			delete g_AllGodModeTimer;
		}
		g_AllGodModeTimer = CreateTimer(GetConVarFloat(LimitedTimeAllGodModeTimer), DisableGodMode, 0);

		CPrintToChatAll("%t", "TankDrawResult_AllLimitedTimeGodMode", attackerName, GetConVarInt(LimitedTimeAllGodModeTimer));
		PrintHintTextToAll("%t", "TankDrawResult_AllLimitedTimeGodMode_NoColor", attackerName, GetConVarInt(LimitedTimeAllGodModeTimer));

		return Plugin_Continue;
	}

	// limited time world moon gravity
	currentChance += chanceLimitedTimeWorldMoonGravity;
	if (random <= currentChance)
	{
		g_WorldGravity = FindConVar("sv_gravity");
		char default_gravity[16];
		g_WorldGravity.GetDefault(default_gravity, sizeof(default_gravity));
		int default_gravity_int = StringToInt(default_gravity);

		g_WorldGravity.IntValue = WorldMoonGravity.IntValue;

		if (g_WorldGravityTimer)
		{
			delete g_WorldGravityTimer;
		}
		g_WorldGravityTimer = CreateTimer(GetConVarFloat(LimitedTimeWorldMoonGravityTimer), ResetWorldGravity, default_gravity_int);
		CPrintToChatAll("%t", "TankDrawResult_LimitedMoonGravity", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityTimer));
		PrintHintTextToAll("%t", "TankDrawResult_LimitedMoonGravity_NoColor", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityTimer));

		return Plugin_Continue;
	}

	// Limited time moon gravity for drawer
	currentChance += chanceMoonGravityOneLimitedTime;
	if (random <= currentChance)
	{
		SetEntityGravity(attacker, GetConVarFloat(SingleMoonGravity));

		if (g_SingleGravityTimer[attacker])
		{
			delete g_SingleGravityTimer[attacker];
		}
		g_SingleGravityTimer[attacker] = CreateTimer(GetConVarFloat(LimitedTimeWorldMoonGravityOne), ResetSingleGravity, attacker);
		CPrintToChatAll("%t", "TankDrawResult_SingleMoonGravity", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityOne));
		PrintHintTextToAll("%t", "TankDrawResult_SingleMoonGravity_NoColor", attackerName, GetConVarInt(LimitedTimeWorldMoonGravityOne));

		return Plugin_Continue;
	}

	// Toggle world moon gravity
	currentChance += chanceWorldMoonGravityToggle;
	if (random <= currentChance)
	{
		g_WorldGravity = FindConVar("sv_gravity");
		char default_gravity[16];
		g_WorldGravity.GetDefault(default_gravity, sizeof(default_gravity));
		int default_gravity_int = StringToInt(default_gravity);

		if (g_WorldGravity.IntValue == default_gravity_int)
		{
			g_WorldGravity.IntValue = WorldMoonGravity.IntValue;
			CPrintToChatAll("%t", "TankDrawResult_EnableMoonGravity", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableMoonGravity_NoColor", attackerName);
		}
		else {
			g_WorldGravity.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableMoonGravity", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableMoonGravity_NoColor", attackerName);
		}
		return Plugin_Continue;
	}

	// Increase gravity for drawer
	currentChance += chanceIncreaseGravity;
	if (random <= currentChance)
	{
		SetEntityGravity(attacker, GetConVarFloat(IncreasedGravity));
		CPrintToChatAll("%t", "TankDrawResult_IncreaseGravity", attackerName, GetConVarFloat(IncreasedGravity));
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseGravity_NoColor", attackerName, GetConVarFloat(IncreasedGravity));

		return Plugin_Continue;
	}

	currentChance += chanceKillSingleSurvivor;
	if (random <= currentChance)
	{
		ForcePlayerSuicide(attacker);
		CPrintToChatAll("%t", "TankDrawResult_KillSingleSurvivor", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_KillSingleSurvivor_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceKillAllSurvivor;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				ForcePlayerSuicide(i);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_KillAllSurvivors", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_KillAllSurvivors_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceIncreaseHealth;
	if (random <= currentChance)
	{
		// Increase player's health randomly
		int minHealth	 = GetConVarInt(MinHealthIncrease);
		int maxHealth	 = GetConVarInt(MaxHealthIncrease);
		int randomHealth = GetRandomInt(minHealth, maxHealth);
		int health	 = GetClientHealth(attacker) + randomHealth;
		SetEntityHealth(attacker, health);
		CPrintToChatAll("%t", "TankDrawResult_IncreaseHealth", attackerName, randomHealth);
		PrintHintTextToAll("%t", "TankDrawResult_IncreaseHealth_NoColor", attackerName, randomHealth);

		return Plugin_Continue;
	}

	currentChance += chanceInfiniteAmmo;
	if (random <= currentChance)
	{
		// Infinite ammo
		g_hInfinitePrimaryAmmo = FindConVar("sv_infinite_ammo");
		if (g_hInfinitePrimaryAmmo.IntValue == 0)
		{
			g_hInfinitePrimaryAmmo.IntValue = 1;
			CPrintToChatAll("%t", "TankDrawResult_EnableInfiniteAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfiniteAmmo_NoColor", attackerName);
		}
		else {
			g_hInfinitePrimaryAmmo.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfiniteAmmo", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfiniteAmmo_NoColor", attackerName);
		}
		return Plugin_Continue;
	}

	currentChance += chanceInfiniteMelee;
	if (random <= currentChance)
	{
		// Infinite melee range
		g_MeleeRange = FindConVar("melee_range");
		char default_range[16];
		g_MeleeRange.GetDefault(default_range, sizeof(default_range));
		int default_range_int = StringToInt(default_range);

		if (g_MeleeRange.IntValue == default_range_int)
		{
			g_MeleeRange.IntValue = GetConVarInt(InfiniteMeeleRange);
			CPrintToChatAll("%t", "TankDrawResult_EnableInfiniteMelee", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_EnableInfiniteMelee_NoColor", attackerName);
		}
		else {
			g_MeleeRange.RestoreDefault();
			CPrintToChatAll("%t", "TankDrawResult_DisableInfiniteMelee", attackerName);
			PrintHintTextToAll("%t", "TankDrawResult_DisableInfiniteMelee_NoColor", attackerName);
		}
		return Plugin_Continue;
	}

	currentChance += chanceAverageHealth;
	if (random <= currentChance)
	{
		// Average all survivors' health
		int health	     = 0;
		int numOfAliveClient = 0;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i) && !IsPlayerIncapacitatedAtAll(i))
			{
				health += GetClientHealth(i);
				numOfAliveClient++;
			}
		}

		int averageHealth = RoundToNearest(float(health) / float(numOfAliveClient));
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i) && !IsPlayerIncapacitatedAtAll(i))
			{
				SetEntityHealth(i, averageHealth);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_AverageHealth", attackerName, averageHealth);
		PrintHintTextToAll("%t", "TankDrawResult_AverageHealth_NoColor", attackerName, averageHealth);

		return Plugin_Continue;
	}

	currentChance += chanceDecreaseHealth;
	if (random <= currentChance)
	{
		int minDecrease	 = GetConVarInt(MinHealthDecrease);
		int maxDecrease	 = GetConVarInt(MaxHealthDecrease);
		int randomHealth = GetRandomInt(minDecrease, maxDecrease);
		int health	 = GetClientHealth(attacker);

		if (health > randomHealth)
		{
			SDKHooks_TakeDamage(attacker, attacker, attacker, float(randomHealth), DMG_GENERIC);
			CPrintToChatAll("%t", "TankDrawResult_DecreaseHealth", attackerName, randomHealth);
			PrintHintTextToAll("%t", "TankDrawResult_DecreaseHealth_NoColor", attackerName, randomHealth);
		}
		else
		{
			SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
			SDKHooks_TakeDamage(attacker, attacker, attacker, float(health) - 1, DMG_GENERIC);
			CPrintToChatAll("%t", "TankDrawResult_DecreaseHealthNotEnough", attackerName, randomHealth, health - 1);
			PrintHintTextToAll("%t", "TankDrawResult_DecreaseHealthNotEnough_NoColor", attackerName, randomHealth, health - 1);
		}

		return Plugin_Continue;
	}

	currentChance += chanceClearAllSurvivorHealth;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				if (!IsPlayerIncapacitatedAtAll(i))
				{
					SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
					SetEntityHealth(i, 1);
				}
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_ClearAllSurvivorHealth", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_ClearAllSurvivorHealth_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceDisarmAllSurvivor;
	if (random <= currentChance)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				DisarmPlayer(i);
			}
		}
		CPrintToChatAll("%t", "TankDrawResult_DisarmAllSurvivors", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_DisarmAllSurvivors_NoColor", attackerName);

		return Plugin_Continue;
	}

	currentChance += chanceDisarmSingleSurvivor;
	if (random <= currentChance)
	{
		DisarmPlayer(attacker);
		CPrintToChatAll("%t", "TankDrawResult_DisarmSingleSurvivor", attackerName);
		PrintHintTextToAll("%t", "TankDrawResult_DisarmSingleSurvivor_NoColor", attackerName);

		return Plugin_Continue;
	}
	// This shouldn't happen, but just in case
	CPrintToChatAll("%t", "TankDraw_SomeThingWrong");
	PrintHintTextToAll("%t", "TankDraw_SomeThingWrong_NoColor");
	return Plugin_Continue;
}

Action ResetSingleGravity(Handle timer, int client)
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

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

bool IsValidAliveClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && (GetClientTeam(client) == 2));
}

bool IsTank(int client)
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

Action ResetWorldGravity(Handle timer, int initValue)
{
	g_WorldGravity = FindConVar("sv_gravity");

	g_WorldGravity.RestoreDefault();

	CPrintToChatAll("%t", "TankDraw_WorldGravityReset");
	PrintHintTextToAll("%t", "TankDraw_WorldGravityReset_NoColor");

	g_WorldGravityTimer = null;

	return Plugin_Continue;
}

bool IsPlayerIncapacitated(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1);
}

bool IsPlayerIncapacitatedAtAll(int client)
{
	return (IsPlayerIncapacitated(client) || IsHangingFromLedge(client));
}

bool IsHangingFromLedge(int client)
{
	return (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1) == 1 || GetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1) == 1);
}

void DisarmPlayer(int client)
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

void EnableGodMode(int iTarget)
{
	int flags = GetEntityFlags(iTarget);
	SetEntityFlags(iTarget, flags | FL_GODMODE);
}

Action DisableGodMode(Handle timer, int iTarget)
{
	if (iTarget != 0)
	{
		int flags = GetEntityFlags(iTarget);
		SetEntityFlags(iTarget, flags & ~FL_GODMODE);
		CPrintToChatAll("%t", "TankDraw_GodModeResetSingle", GetName(iTarget));
		PrintHintTextToAll("%t", "TankDraw_GodModeResetSingle_NoColor", GetName(iTarget));
		g_SingleGodModeTimer[iTarget] = null;
	}
	else {
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				int flags = GetEntityFlags(i);
				SetEntityFlags(i, flags & ~FL_GODMODE);
			}
		}
		CPrintToChatAll("%t", "TankDraw_GodModeResetAll");
		PrintHintTextToAll("%t", "TankDraw_GodModeResetAll_NoColor");
		g_AllGodModeTimer = null;
	}
	return Plugin_Continue;
}

void ResetAllTimer()
{
	// reset single gravity timer
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_SingleGodModeTimer[i])
		{
			delete g_SingleGodModeTimer[i];
		}
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
	// reset god mode for all timer
	if (g_AllGodModeTimer)
	{
		delete g_AllGodModeTimer;
	}
}

char[] GetName(int client)
{
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	return clientName;
}

public Action MenuFunc_MainMenu(int client, int args)
{
	Handle menu = CreateMenu(MenuHandler_MainMenu);
	char   line[1024];

	FormatEx(line, sizeof(line), "抽奖调试菜单 / tank draw debug menu");
	SetMenuTitle(menu, line);
	AddMenuItem(menu, "item0", "杀死tank / kill tank");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);

	return Plugin_Continue;
}

public int MenuHandler_MainMenu(Handle menu, MenuAction action, int client, int item)
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

public Action MenuFunc_KillTank(int client)
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

public int MenuHandler_KillTank(Handle menu, MenuAction action, int client, int item)
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