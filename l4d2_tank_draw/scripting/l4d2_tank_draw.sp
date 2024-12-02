#pragma semicolon 1
#pragma newdecls required 1	   // force new syntax

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <left4dhooks>

#include "../../lib/helper.sp"

#include "lib/lib.sp"
#include "lib/timer_bomb.sp"
#include "lib/dev_menu.sp"
#include "lib/lucky_draw.sp"

#define PLUGIN_VERSION "2.3.0"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

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

	AverageHealthChance		  = CreateConVar("l4d2_tank_draw_average_health_chance", "10", "平均生命值的概率 / Probability of average health", FCVAR_NONE);

	ClearAllSurvivorHealthChance	  = CreateConVar("l4d2_tank_draw_clear_all_survivor_health_chance", "10", "清空所有人血量概率 / Probability of clearing all survivors' health", FCVAR_NONE);

	DebugMode			  = CreateConVar("l4d2_tank_draw_debug_mode", "0", "是否开启调试模式，修改后tank被击杀即可抽奖，使用!x开启击杀tank菜单 / Enable debug mode, draw after tank is killed when enabled, use !x open kill tank menu", false, false);

	DecreaseHealthChance		  = CreateConVar("l4d2_tank_draw_decrease_health_chance", "10", "抽奖受到伤害的概率 / Probability of receiving damage", FCVAR_NONE);
	DecreaseHealthMax		  = CreateConVar("l4d2_tank_draw_decrease_health_max", "500", "抽奖受到伤害的最大值 / Maximum value for health decrease", false, false);
	DecreaseHealthMin		  = CreateConVar("l4d2_tank_draw_decrease_health_min", "200", "抽奖受到伤害的最小值 / Minimum value for health decrease", false, false);

	DisarmAllSurvivorChance		  = CreateConVar("l4d2_tank_draw_disarm_all_survivor_chance", "10", "所有人缴械概率 / Probability of disarming all survivors", FCVAR_NONE);
	DisarmSingleSurvivorChance	  = CreateConVar("l4d2_tank_draw_disarm_single_survivor_chance", "10", "单人缴械概率 / Probability of disarming a single survivor", FCVAR_NONE);

	Enable				  = CreateConVar("l4d2_tank_draw_enable", "1", "Tank抽奖插件开/关 [1=开|0=关]。 / Tank draw plugin on/off [1=on|0=off].", PLUGIN_FLAG, true, 0.0, true, 1.0);

	GravityIncreasedChance		  = CreateConVar("l4d2_tank_draw_gravity_increased_chance", "10", "增加单人重力的概率 / Probability of increasing single player gravity", FCVAR_NONE);
	GravityIncreasedMultiplier	  = CreateConVar("l4d2_tank_draw_gravity_increased_multiplier", "2.0", "抽奖增加单人重力的倍数，从1.0至8.0 / Multiplier for increasing single player gravity, from 1.0 to 8.0", PLUGIN_FLAG, true, 1.0, true, 8.0);

	GravityMoonSingleChance		  = CreateConVar("l4d2_tank_draw_gravity_moon_single_chance", "10", "抽奖者单人获得限时月球重力的概率 / Probability of single player getting limited time moon gravity", FCVAR_NONE);
	GravityMoonSingle		  = CreateConVar("l4d2_tank_draw_gravity_moon_single", "0.1", "单人月球重力参数，人物正常重力值为1 / Single player moon gravity parameter, normal gravity is 1", false, false);
	GravityMoonSingleDuration	  = CreateConVar("l4d2_tank_draw_gravity_moon_single_duration", "180", "单人限时月球重力持续秒数 / Duration in seconds for single player limited time moon gravity", false, false);

	GravityMoonWorld		  = CreateConVar("l4d2_tank_draw_gravity_moon_world", "80", "月球重力时世界重力参数，世界重力正常值为800 / World gravity parameter for moon gravity, normal world gravity is 800", false, false);
	GravityMoonWorldChance		  = CreateConVar("l4d2_tank_draw_gravity_moon_world_chance", "10", "获得限时世界重力改为月球重力的概率 / Probability of getting limited time world moon gravity", FCVAR_NONE);
	GravityMoonWorldDuration	  = CreateConVar("l4d2_tank_draw_gravity_moon_world_duration", "180", "限时世界重力改为月球重力持续秒数 / Duration in seconds for limited time world moon gravity", false, false);
	GravityMoonWorldToggleChance	  = CreateConVar("l4d2_tank_draw_gravity_moon_world_toggle_chance", "5", "世界重力切换为月球重力的概率 / Probability of toggling world gravity to moon gravity", FCVAR_NONE);

	HealthIncreaseChance		  = CreateConVar("l4d2_tank_draw_health_increase_chance", "10", "增加生命值的概率 / Probability of increasing health", FCVAR_NONE);
	HealthIncreaseMax		  = CreateConVar("l4d2_tank_draw_health_increase_max", "500", "抽奖增加血量的最大值 / Maximum value for health increase", false, false);
	HealthIncreaseMin		  = CreateConVar("l4d2_tank_draw_health_increase_min", "200", "抽奖增加血量的最小值 / Minimum value for health increase", false, false);

	InfiniteAmmoChance		  = CreateConVar("l4d2_tank_draw_infinite_ammo_chance", "10", "无限弹药的概率 / Probability of infinite ammo", FCVAR_NONE);
	KillSurvivorMolotovChance	  = CreateConVar("l4d2_tank_draw_infinite_ammo_kill_survivor_molotov_chance", "30", "无限弹药时，玩家乱扔火时处死概率（百分比，0为关闭） / Probability of killing a survivor when throwing molotovs recklessly with infinite ammo (percentage, 0 to disable)", FCVAR_NONE);
	DisarmSurvivorMolotovChance	  = CreateConVar("l4d2_tank_draw_infinite_ammo_disarm_survivor_molotov_chance", "30", "无限弹药时，玩家乱扔火时缴械概率（百分比，0为关闭） / Probability of disarming a survivor when throwing molotovs recklessly with infinite ammo (percentage, 0 to disable)", FCVAR_NONE);

	InfiniteMeleeChance		  = CreateConVar("l4d2_tank_draw_infinite_melee_chance", "5", "无限近战范围的概率 / Probability of infinite melee range", FCVAR_NONE);
	InfiniteMeleeRange		  = CreateConVar("l4d2_tank_draw_infinite_melee_range", "700", "无限近战范围，游戏默认为70，重复抽取会自动恢复默认值 / Infinite melee range, game default is 70, repeated draws will restore default value", false, false);

	KillAllSurvivorChance		  = CreateConVar("l4d2_tank_draw_kill_all_survivor_chance", "10", "团灭概率 / Probability of killing all survivors", FCVAR_NONE);

	KillSingleSurvivorChance	  = CreateConVar("l4d2_tank_draw_kill_single_survivor_chance", "10", "单人死亡概率 / Probability of killing a single survivor", FCVAR_NONE);

	NewTankChance			  = CreateConVar("l4d2_tank_draw_new_tank_chance", "30", "获得tank概率 / Probability of a tank", FCVAR_NONE);

	NoPriceChance			  = CreateConVar("l4d2_tank_draw_no_price_chance", "20", "没有奖励的概率 / Probability of no reward", FCVAR_NONE);

	ReviveAllDeadChance		  = CreateConVar("l4d2_tank_draw_revive_all_dead_chance", "30", "全体复活概率 / Probability of reviving all dead", FCVAR_NONE);

	TimerBombChance			  = CreateConVar("l4d2_tank_draw_timer_bomb_chance", "30", "变成定时炸弹概率 / Probability of becoming a timer bomb", FCVAR_NONE);
	TimerBombDamage			  = CreateConVar("l4d2_tank_draw_timer_bomb_damage", "100", "定时炸弹范围伤害值 / Damage caused by the timer bomb within the explosion range", FCVAR_NONE);
	TimerBombDuration		  = CreateConVar("l4d2_tank_draw_timer_bomb_duration", "8", "定时炸弹倒计时秒数 / Countdown duration in seconds before the timer bomb explodes", FCVAR_NONE);
	TimerBombRadius			  = CreateConVar("l4d2_tank_draw_timer_bomb_radius", "300.0", "定时炸弹爆炸范围 / Radius of the timer bomb explosion", FCVAR_NONE);

	AutoExecConfig(true, "l4d2_tank_draw");

	PrintToServer("[Tank Draw] Plugin loaded");
	PrintToServer("[Tank Draw] debug mode: %d", L4D2TankDrawDebugMode.IntValue);

	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_death", Event_PlayerDeath);

	HookEvent("molotov_thrown", Event_Molotov);

	HookEvent("finale_vehicle_leaving", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("map_transition", Event_RoundEnd, EventHookMode_Pre);
	HookEvent("finale_win", Event_RoundEnd, EventHookMode_Pre);

	if (L4D2TankDrawDebugMode.IntValue == 1)
	{
		PrintToServer("调试菜单打开 / debug menu on");
		RegConsoleCmd("sm_x", MenuFunc_MainMenu, "打开调试菜单 / open debug menu");
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
	if (IsValidSurvivor(victim))
	{
		PrintToServer("player %d dead, reset player value", victim);

		SetEntityGravity(victim, 1.0);

		KillTimeBomb(victim);
	}

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

	ResetAllTimer();
	ResetAllValue();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }

	ResetAllTimer();
	ResetAllValue();

	return Plugin_Continue;
}