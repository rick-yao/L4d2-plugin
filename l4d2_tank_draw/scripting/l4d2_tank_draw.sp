/*
 * @author Rick Yao https://github.com/rick-yao
 * @repository https://github.com/rick-yao/L4d2-plugin
 *
 * Changelog
 * v2.9.0 - 2024-12-15
 * - change doc
 *
 * v2.8.0 - 2024-12-12
 * - add infinite primary ammo
 *
 * v2.7.0 - 2024-12-12
 * - add reset all survivor health
 *
 * v2.6.0 - 2024-12-12
 * - refactor the operation of timer, make it more robust
 *
 * v2.5.0 - 2024-12-11
 * - add new witch
 *
 * v2.4.0 - 2024-12-10
 * - add freeze time bomb
 *
 * v2.3.3 - 2024-12-10
 * - reset survivor value when mission lost
 *
 * v2.3.2 - 2024-12-10
 * - clear survivor timer and other value if survivor died or disconnected
 *
 * v2.3.1 - 2024-12-10
 * - clear temp health when average health
 *
 * for changelog before 2.3.0 please checkout commit history
 *
 */
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
#include "lib/freeze_timer_bomb.sp"
#include "lib/dev_menu.sp"
#include "lib/lucky_draw.sp"

#define PLUGIN_VERSION "2.9.0"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

public Plugin myinfo =
{
	author	    = "Rick Yao",
	name	    = "L4D2 Tank Draw",
	description = "Face your destiny after killing tank with melee",
	url	    = "https://github.com/rick-yao/L4d2-plugin",
	version	    = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	LoadTranslations("l4d2_tank_draw.phrases");

	ChanceAverageHealth		  = CreateConVar("l4d2_tank_draw_average_health_chance", "0", "平均生命值的概率(平均所有站立状态幸存者的实际血量，清空临时血量) \nProbability of averaging all standing survivors' actual health, clearing temporary health", FCVAR_NONE);

	ChanceClearAllSurvivorHealth	  = CreateConVar("l4d2_tank_draw_clear_all_survivor_health_chance", "0", "清空所有人血量概率(将所有站立状态幸存者实际血量变成1，清空临时血量) \nProbability of setting all standing survivors' actual health to 1 and clearing temporary health", FCVAR_NONE);

	L4D2TankDrawDebugMode		  = CreateConVar("l4d2_tank_draw_debug_mode", "0", "是否开启调试模式，修改后tank被任意武器击杀即可抽奖，使用!x开启击杀tank菜单 \nEnable debug mode. When enabled, any weapon killing a tank triggers a draw. Use !x to open the kill tank menu", false, false);

	ChanceDecreaseHealth		  = CreateConVar("l4d2_tank_draw_decrease_health_chance", "0", "抽奖受到伤害的概率(伤害超过血量时，将血量设置为1而不是倒地) \nProbability of taking damage. If damage exceeds health, health is set to 1 instead of incapacitation", FCVAR_NONE);
	MaxHealthDecrease		  = CreateConVar("l4d2_tank_draw_decrease_health_max", "500", "抽奖受到伤害的最大值 \nMaximum damage value received during the draw", false, false);
	MinHealthDecrease		  = CreateConVar("l4d2_tank_draw_decrease_health_min", "200", "抽奖受到伤害的最小值 \nMinimum damage value received during the draw", false, false);

	ChanceDisarmAllSurvivor		  = CreateConVar("l4d2_tank_draw_disarm_all_survivor_chance", "0", "所有人缴械概率(清空所有槽位道具) \nProbability of disarming all survivors by clearing all item slots", FCVAR_NONE);
	ChanceDisarmSingleSurvivor	  = CreateConVar("l4d2_tank_draw_disarm_single_survivor_chance", "0", "单人缴械概率 \nProbability of disarming a single survivor", FCVAR_NONE);

	TankDrawEnable			  = CreateConVar("l4d2_tank_draw_enable", "1", "Tank抽奖插件开/关 [1=开|0=关]。 \nEnable or disable the Tank draw plugin [1=on|0=off]", PLUGIN_FLAG, true, 0.0, true, 1.0);

	ChanceDisableGlow		  = CreateConVar("l4d2_tank_draw_disable_glow_chance", "0", "取消人物光圈概率(取消人物轮廓光圈，人物头上的名字依然保留，不建议使用，很多插件会修改光圈) \nProbability of disabling survivor glow. Removes survivor outline glow but keeps name above the head. Not recommended as many plugins modify the glow", FCVAR_NONE);

	ChanceIncreaseGravity		  = CreateConVar("l4d2_tank_draw_gravity_increased_chance", "0", "增加单人重力的概率(爬梯子可以解除buff) \nProbability of increasing gravity for a single player. Buff can be removed by climbing a ladder", FCVAR_NONE);
	IncreasedGravity		  = CreateConVar("l4d2_tank_draw_gravity_increased_multiplier", "3.0", "抽奖增加单人重力的倍数，从1.0至8.0 \nMultiplier for increasing single player gravity during the draw, from 1.0 to 8.0", PLUGIN_FLAG, true, 1.0, true, 8.0);

	ChanceMoonGravityOneLimitedTime	  = CreateConVar("l4d2_tank_draw_gravity_moon_single_chance", "0", "抽奖者单人获得限时月球重力的概率(爬梯子可以解除buff) \nProbability of a single player receiving limited-time moon gravity. Buff can be removed by climbing a ladder", FCVAR_NONE);
	SingleMoonGravity		  = CreateConVar("l4d2_tank_draw_gravity_moon_single", "0.1", "单人月球重力参数，人物正常重力值为1 \nMoon gravity parameter for a single player. Normal gravity value is 1", false, false);
	LimitedTimeWorldMoonGravityOne	  = CreateConVar("l4d2_tank_draw_gravity_moon_single_duration", "180", "单人限时月球重力持续秒数 \nDuration in seconds for single player limited-time moon gravity", false, false);

	WorldMoonGravity		  = CreateConVar("l4d2_tank_draw_gravity_moon_world", "80", "月球重力时世界重力参数，世界重力正常值为800(游戏全局参数，爬梯子不可解除buf，非限时重复抽取会恢复默认值) \nWorld gravity parameter during moon gravity. Normal world gravity is 800. Buff cannot be removed by climbing a ladder. Non-timed repeated draws will reset to default", false, false);
	ChanceLimitedTimeWorldMoonGravity = CreateConVar("l4d2_tank_draw_gravity_moon_world_chance", "0", "获得限时世界重力改为月球重力的概率(重复抽取会重置计时器) \nProbability of changing world gravity to moon gravity for a limited time. Repeated draws reset the timer", FCVAR_NONE);
	LimitedTimeWorldMoonGravityTimer  = CreateConVar("l4d2_tank_draw_gravity_moon_world_duration", "180", "限时世界重力改为月球重力持续秒数 \nDuration in seconds for limited-time world moon gravity", false, false);
	ChanceWorldMoonGravityToggle	  = CreateConVar("l4d2_tank_draw_gravity_moon_world_toggle_chance", "0", "世界重力切换为月球重力的概率 \nProbability of toggling world gravity to moon gravity", FCVAR_NONE);

	ChanceIncreaseHealth		  = CreateConVar("l4d2_tank_draw_health_increase_chance", "0", "增加生命值的概率(幸存者总血量无法突破服务器设置的最大生命值) \nProbability of increasing health. Survivors' total health cannot exceed the server's maximum health setting", FCVAR_NONE);
	MaxHealthIncrease		  = CreateConVar("l4d2_tank_draw_health_increase_max", "500", "抽奖增加血量的最大值 \nMaximum health increase value during the draw", false, false);
	MinHealthIncrease		  = CreateConVar("l4d2_tank_draw_health_increase_min", "200", "抽奖增加血量的最小值 \nMinimum health increase value during the draw", false, false);

	ChanceInfiniteAmmo		  = CreateConVar("l4d2_tank_draw_infinite_ammo_chance", "0", "无限弹药的概率(游戏全局参数，重复抽取会恢复默认，和主武器无限弹药只能同时有一个生效) \nProbability of infinite ammo. Global game parameter. Repeated draws reset to default. Cannot coexist with infinite primary weapon ammo", FCVAR_NONE);
	ChanceKillSurvivorMolotov	  = CreateConVar("l4d2_tank_draw_infinite_ammo_kill_survivor_molotov_chance", "0", "无限弹药时，玩家乱扔火时处死概率（百分比，0为关闭） \nProbability (percentage, 0 to disable) of killing a survivor when recklessly throwing molotovs with infinite ammo", FCVAR_NONE);
	ChanceDisarmSurvivorMolotov	  = CreateConVar("l4d2_tank_draw_infinite_ammo_disarm_survivor_molotov_chance", "0", "无限弹药时，玩家乱扔火时缴械概率（百分比，0为关闭） \nProbability (percentage, 0 to disable) of disarming a survivor when recklessly throwing molotovs with infinite ammo", FCVAR_NONE);
	ChanceTimerBombMolotov		  = CreateConVar("l4d2_tank_draw_infinite_ammo_timer_bomb_molotov_chance", "0", "无限弹药时，玩家乱扔火时变成定时炸弹概率（百分比，0为关闭） \nProbability (percentage, 0 to disable) of becoming a timer bomb when recklessly throwing molotovs with infinite ammo", FCVAR_NONE);

	ChanceInfinitePrimaryAmmo	  = CreateConVar("l4d2_tank_draw_infinite_primary_ammo_chance", "0", "主武器无限弹药的概率(游戏全局参数，重复抽取会恢复默认，和无限弹药只能同时有一个生效) \nProbability of infinite primary weapon ammo. Global game parameter. Repeated draws reset to default. Cannot coexist with infinite ammo", FCVAR_NONE);

	ChanceInfiniteMelee		  = CreateConVar("l4d2_tank_draw_infinite_melee_chance", "0", "无限近战范围的概率(游戏全局参数，重复抽取会恢复默认) \nProbability of infinite melee range. Global game parameter. Repeated draws reset to default", FCVAR_NONE);
	InfiniteMeeleRange		  = CreateConVar("l4d2_tank_draw_infinite_melee_range", "700", "无限近战范围，游戏默认为70，重复抽取会自动恢复默认值 \nInfinite melee range. Default is 70. Repeated draws automatically restore default value", false, false);

	ChanceKillAllSurvivor		  = CreateConVar("l4d2_tank_draw_kill_all_survivor_chance", "0", "团灭概率 \nProbability of killing all survivors (team wipe)", FCVAR_NONE);

	ChanceKillSingleSurvivor	  = CreateConVar("l4d2_tank_draw_kill_single_survivor_chance", "0", "单人死亡概率 \nProbability of killing a single survivor", FCVAR_NONE);

	ChanceResetAllSurvivorHealth	  = CreateConVar("l4d2_tank_draw_reset_all_survivor_health_chance", "0", "重置所有人血量概率(将所有人血量设置为100，清空倒地次数记数) \nProbability of resetting all survivors' health to 100 and clearing incapacitation counters", FCVAR_NONE);

	ChanceNewTank			  = CreateConVar("l4d2_tank_draw_new_tank_chance", "0", "获得tank概率 \nProbability of spawning a new tank", FCVAR_NONE);
	ChanceNewWitch			  = CreateConVar("l4d2_tank_draw_new_witch_chance", "0", "获得witch概率 \nProbability of spawning a new witch", FCVAR_NONE);

	ChanceNoPrice			  = CreateConVar("l4d2_tank_draw_no_price_chance", "10", "没有奖励的概率 \nProbability of receiving no reward", FCVAR_NONE);

	ChanceReviveAllDead		  = CreateConVar("l4d2_tank_draw_revive_all_dead_chance", "0", "全体复活概率 \nProbability of reviving all dead survivors", FCVAR_NONE);

	ChanceTimerBomb			  = CreateConVar("l4d2_tank_draw_timer_bomb_chance", "0", "变成定时炸弹概率(重复抽取会取消计时) \nProbability of becoming a timer bomb. Repeated draws cancel the timer", FCVAR_NONE);
	TimerBombRangeDamage		  = CreateConVar("l4d2_tank_draw_timer_bomb_damage", "200", "定时炸弹范围伤害值 \nDamage caused by the timer bomb within its explosion range", FCVAR_NONE);
	TimerBombSecond			  = CreateConVar("l4d2_tank_draw_timer_bomb_duration", "8", "定时炸弹倒计时秒数 \nCountdown duration in seconds before the timer bomb explodes", FCVAR_NONE);
	TimerBombRadius			  = CreateConVar("l4d2_tank_draw_timer_bomb_radius", "500.0", "定时炸弹爆炸范围 \nRadius of the timer bomb explosion", FCVAR_NONE);

	ChanceFreezeBomb		  = CreateConVar("l4d2_tank_draw_freeze_bomb_chance", "0", "变成冰冻炸弹概率(重复抽取会取消计时) \nProbability of becoming a freeze bomb. Repeated draws cancel the timer", FCVAR_NONE);
	FreezeBombDuration		  = CreateConVar("l4d2_tank_draw_freeze_duration", "15", "冰冻持续时间 \nDuration of the freeze effect in seconds", FCVAR_NONE);
	FreezeBombCountDown		  = CreateConVar("l4d2_tank_draw_freeze_bomb_countdown", "8", "冰冻炸弹倒计时秒数 \nCountdown duration in seconds before the freeze bomb explodes", FCVAR_NONE);
	FreezeBombRadius		  = CreateConVar("l4d2_tank_draw_freeze_bomb_radius", "500.0", "冰冻炸弹范围 \nRadius of the freeze bomb effect", FCVAR_NONE);

	AutoExecConfig(true, "l4d2_tank_draw");

	PrintToServer("[Tank Draw] Plugin loaded");
	PrintToServer("[Tank Draw] debug mode: %d", L4D2TankDrawDebugMode.IntValue);

	HookEvent("player_incapacitated", Event_PlayerIncapacitated);

	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("mission_lost", Event_Lost, EventHookMode_Pre);

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
	PrintToServer("[Tank Draw] Event_PlayerIncapacitated triggered.");

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

// reset value when player died
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }
	PrintToServer("[Tank Draw] Event_PlayerDeath triggered.");

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidSurvivor(victim))
	{
		PrintToServer("player %d dead, reset player value", victim);

		ResetClient(victim);
	}

	return Plugin_Continue;
}

// reset value when player disconnect
public void OnClientDisconnect(int client)
{
	if (TankDrawEnable.IntValue == 0) { return; }
	PrintToServer("[Tank Draw] OnClientDisconnect triggered.");

	if (IsValidSurvivor(client))
	{
		PrintToServer("player %d disconnect, reset player value", client);

		ResetClient(client);
	}

	return;
}

public Action Event_Molotov(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("[Tank Draw] Event_Molotov triggered.");

	g_hInfiniteAmmo = FindConVar("sv_infinite_ammo");
	if (g_hInfiniteAmmo.IntValue == 1)
	{
		int  random			 = GetRandomInt(1, 100);
		int  chanceDisarmSurvivorMolotov = ChanceDisarmSurvivorMolotov.IntValue;
		int  chanceKillSurvivorMolotov	 = ChanceKillSurvivorMolotov.IntValue;
		int  chanceTimerBombMolotov	 = ChanceTimerBombMolotov.IntValue;

		int  attacker			 = GetClientOfUserId(event.GetInt("userid"));
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		if (random <= chanceDisarmSurvivorMolotov)
		{
			L4D_RemoveAllWeapons(attacker);

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
		if (random <= chanceDisarmSurvivorMolotov + chanceKillSurvivorMolotov + chanceTimerBombMolotov)
		{
			if (g_hTimeBombTimer[attacker] != INVALID_HANDLE)
			{
				KillTimer(g_hTimeBombTimer[attacker]);
				g_hTimeBombTimer[attacker] = INVALID_HANDLE;
				g_iTimeBombTicks[attacker] = 0;

				// Reset player color
				SetEntityRenderColor(attacker, 255, 255, 255, 255);

				CPrintToChatAll("%t", "TankDraw_CancelTimerBomb_Molotov", attackerName);
				PrintHintTextToAll("%t", "TankDraw_CancelTimerBomb_Molotov_NoColor", attackerName);

				return Plugin_Continue;
			}
			else {
				SetPlayerTimeBomb(attacker, TimerBombSecond.IntValue, TimerBombRadius.FloatValue, TimerBombRangeDamage.IntValue);
				CheatCommand(attacker, "give", "adrenaline");

				CPrintToChatAll("%t", "TankDraw_TimerBomb_Molotov", attackerName);
				PrintHintTextToAll("%t", "TankDraw_TimerBomb_Molotov_NoColor", attackerName);
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public void OnMapEnd()
{
	if (TankDrawEnable.IntValue == 0) { return; }
	PrintToServer("[Tank Draw] MapEnd triggered.");

	ResetAllTimer();
	ResetAllValue();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }
	PrintToServer("[Tank Draw] Event_RoundEnd triggered.");

	ResetAllTimer();
	ResetAllValue();

	return Plugin_Continue;
}

public Action Event_Lost(Event event, const char[] name, bool dontBroadcast)
{
	if (TankDrawEnable.IntValue == 0) { return Plugin_Continue; }
	PrintToServer("[Tank Draw] Event_Lost triggered.");

	KillAllTimeBombs();
	KillAllFreezeBombs();

	KillAllSingleGravityTimer();

	return Plugin_Continue;
}