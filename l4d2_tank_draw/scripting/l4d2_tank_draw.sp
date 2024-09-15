#pragma semicolon 1
#pragma newdecls required 1	   // force new syntax

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.4"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

#define Z_TANK	       8

ConVar g_hInfinitePrimaryAmmo;
ConVar g_MeleeRange;

// Custom ConVars for the plugin
ConVar ChanceNoPrice;
ConVar ChanceIncreaseHealth;
ConVar ChanceInfiniteAmmo;
ConVar ChanceInfiniteMelee;
ConVar ChanceMoonGravityAll;
ConVar ChanceMoonGravityOne;
ConVar ChanceAverageHealth;
ConVar ChanceMoonGravityToggle;
ConVar ChanceIncreaseGravity;
ConVar ChanceDecreaseHealth;
ConVar ChanceKillAllSurvivor;
ConVar ChanceKillSingleSurvivor;

ConVar MoonGravity;
ConVar MoonGravityOneShotTime;
ConVar InfiniteMeeleRange;
ConVar L4D2TankDrawDebugMode;
ConVar MinHealthIncrease;
ConVar MaxHealthIncrease;
ConVar MinHealthDecrease;
ConVar MaxHealthDecrease;
ConVar IncreasedGravity;

public Plugin myinfo =
{
	author	    = "Rick",
	name	    = "L4D2 Tank Draw",
	description = "Face your destiny after killing a tank",
	version	    = PLUGIN_VERSION,


}

int IsMoonGravity = 0;

public void OnPluginStart()
{
	MoonGravity		 = CreateConVar("l4d2_tank_draw_moongravity", "0.1", "月球重力参数，正常值为1.0", false, false);
	IncreasedGravity	 = CreateConVar("l4d2_tank_draw_increased_gravity", "2.0", "抽奖增加重力的倍数，从1.0至8.0", PLUGIN_FLAG, true, 1.0, true, 8.0);
	MoonGravityOneShotTime	 = CreateConVar("l4d2_tank_draw_moongravityoneshottime", "180", "限时月球重力持续秒数", false, false);
	L4D2TankDrawDebugMode	 = CreateConVar("l4d2_tank_draw_debug_mode", "0", "是否开启调试模式，修改后会影响抽奖结果，总是同一个结果", false, false);
	InfiniteMeeleRange	 = CreateConVar("l4d2_tank_draw_infinite_melee_range", "700", "游戏默认为70，会自动恢复", false, false);
	MinHealthIncrease	 = CreateConVar("l4d2_tank_draw_min_health_increase", "200", "抽奖增加血量的最小值", false, false);
	MaxHealthIncrease	 = CreateConVar("l4d2_tank_draw_max_health_increase", "500", "抽奖增加血量的最大值", false, false);
	MinHealthDecrease	 = CreateConVar("l4d2_tank_draw_min_health_decrease", "200", "抽奖减少血量的最小值", false, false);
	MaxHealthDecrease	 = CreateConVar("l4d2_tank_draw_max_health_decrease", "500", "抽奖减少血量的最大值", false, false);

	ChanceNoPrice		 = CreateConVar("l4d2_tank_draw_chance_no_price", "20", "没有奖励的概率（百分比）", FCVAR_NONE);
	ChanceIncreaseHealth	 = CreateConVar("l4d2_tank_draw_chance_increase_health", "10", "增加生命值的概率（百分比）", FCVAR_NONE);
	ChanceInfiniteAmmo	 = CreateConVar("l4d2_tank_draw_chance_infinite_ammo", "10", "无限弹药的概率（百分比）", FCVAR_NONE);
	ChanceInfiniteMelee	 = CreateConVar("l4d2_tank_draw_chance_infinite_melee", "5", "无限近战范围的概率（百分比）", FCVAR_NONE);
	ChanceMoonGravityAll	 = CreateConVar("l4d2_tank_draw_chance_moon_gravity_all", "10", "所有人获得限时月球重力的概率（百分比）", FCVAR_NONE);
	ChanceMoonGravityOne	 = CreateConVar("l4d2_tank_draw_chance_moon_gravity_one", "10", "抽奖者获得限时月球重力的概率（百分比）", FCVAR_NONE);
	ChanceAverageHealth	 = CreateConVar("l4d2_tank_draw_chance_average_health", "10", "平均生命值的概率（百分比）", FCVAR_NONE);
	ChanceMoonGravityToggle	 = CreateConVar("l4d2_tank_draw_chance_moon_gravity_toggle", "5", "切换月球重力的概率（百分比）", FCVAR_NONE);
	ChanceIncreaseGravity	 = CreateConVar("l4d2_tank_draw_chance_increase_gravity", "10", "增加重力的概率（百分比）", FCVAR_NONE);
	ChanceDecreaseHealth	 = CreateConVar("l4d2_tank_draw_chance_decrease_health", "10", "减少生命值的概率（百分比）", FCVAR_NONE);
	ChanceKillAllSurvivor	 = CreateConVar("l4d2_tank_draw_chance_kill_all_survivor", "10", "团灭概率", FCVAR_NONE);
	ChanceKillSingleSurvivor = CreateConVar("l4d2_tank_draw_chance_kill_single_survivor", "10", "单人死亡概率", FCVAR_NONE);

	PrintToServer("[Tank Draw] Plugin loaded");
	PrintToServer("[Tank Draw] debug mode: %d", L4D2TankDrawDebugMode.IntValue);

	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_Roundend);
	HookEvent("finale_vehicle_leaving", Event_Roundend);
	HookEvent("mission_lost", Event_Roundend);
	HookEvent("map_transition", Event_Roundend);

	AutoExecConfig(true, "l4d2_tank_draw");
}

public Action Event_PlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
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
			PrintToServer("[Tank Draw] Attacker is not a valid alive client. Exiting event.");
			return Plugin_Continue;
		}

		// now the attacker is a valid alive client and the weapon is a melee weapon
		// so we can make the tank draw
		PrintToServer("[Tank Draw] Event_PlayerDeath triggered. Victim: %d, Attacker: %d, weapon: %s", victim, attacker, weapon);

		char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
		GetClientName(victim, victimName, sizeof(victimName));
		GetClientName(attacker, attackerName, sizeof(attackerName));
		TankDraw_PrintToChat(0, "%s 被玩家 %s 用近战武器击杀，开始幸运抽奖", victimName, attackerName);

		// Lucky draw logic
		LuckyDraw(victim, attacker);

		TankDraw_PrintToChat(0, "幸运抽奖结束");

		return Plugin_Continue;
	}
	else {
		PrintToServer("[Tank Draw] No Melee weapon detected. Exiting event.");
		TankDraw_PrintToChat(0, "Tank不是被砍死的，停止抽奖");
		return Plugin_Continue;
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// reset value when player died
	int victim = GetClientOfUserId(event.GetInt("userid"));
	PrintToServer("player dead... %d", victim);

	SetEntityGravity(victim, 1.0);

	return Plugin_Continue;
}

public Action Event_Roundend(Event event, const char[] name, bool dontBroadcast)
{
	// reset all changed server value
	g_hInfinitePrimaryAmmo		= FindConVar("sv_infinite_ammo");
	g_hInfinitePrimaryAmmo.IntValue = 0;
	g_MeleeRange			= FindConVar("melee_range");
	g_MeleeRange.IntValue		= 70;

	IsMoonGravity			= 0;
	return Plugin_Continue;
}

Action LuckyDraw(int victim, int attacker)
{
	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));

	TankDraw_PrintToChat(0, "幸运抽奖开始");

	int random;
	int totalChance		     = 0;
	int chanceNoPrice	     = ChanceNoPrice.IntValue;

	int chanceIncreaseHealth     = ChanceIncreaseHealth.IntValue;
	int chanceInfiniteAmmo	     = ChanceInfiniteAmmo.IntValue;
	int chanceInfiniteMelee	     = ChanceInfiniteMelee.IntValue;
	int chanceMoonGravityAll     = ChanceMoonGravityAll.IntValue;
	int chanceMoonGravityOne     = ChanceMoonGravityOne.IntValue;
	int chanceAverageHealth	     = ChanceAverageHealth.IntValue;
	int chanceMoonGravityToggle  = ChanceMoonGravityToggle.IntValue;
	int chanceIncreaseGravity    = ChanceIncreaseGravity.IntValue;
	int chanceDecreaseHealth     = ChanceDecreaseHealth.IntValue;
	int chanceKillAllSurvivor    = ChanceKillAllSurvivor.IntValue;
	int chanceKillSingleSurvivor = ChanceKillSingleSurvivor.IntValue;

	totalChance		     = chanceNoPrice + chanceKillAllSurvivor + chanceKillSingleSurvivor + chanceIncreaseHealth + chanceInfiniteAmmo + chanceInfiniteMelee + chanceMoonGravityAll + chanceMoonGravityOne + chanceAverageHealth + chanceMoonGravityToggle + chanceIncreaseGravity + chanceDecreaseHealth;

	random			     = GetRandomInt(1, totalChance);

	int currentChance	     = 0;

	currentChance += chanceNoPrice;
	if (random <= currentChance)
	{
		TankDraw_PrintToChat(0, "非常遗憾，此次砍死tank没有中奖");
		return Plugin_Continue;
	}

	currentChance += chanceKillSingleSurvivor;
	if (random <= currentChance)
	{
		ForcePlayerSuicide(attacker);
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：立刻死亡", attackerName);
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
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：团灭", attackerName);
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
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：随机增加 %d 血量", attackerName, randomHealth);
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
			TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：所有人无限子弹", attackerName);
		}
		else {
			g_hInfinitePrimaryAmmo.IntValue = 0;
			TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：关闭无限子弹", attackerName);
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
			TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：无限近战", attackerName);
		}
		else {
			g_MeleeRange.RestoreDefault();
			TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：关闭无限近战", attackerName);
		}
		return Plugin_Continue;
	}

	currentChance += chanceMoonGravityAll;
	if (random <= currentChance)
	{
		// Limited time moon gravity for all
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				SetEntityGravity(i, GetConVarFloat(MoonGravity));
			}
		}
		StringMap data = new StringMap();
		data.SetValue("client", attacker);
		data.SetValue("resetAll", true);
		CreateTimer(GetConVarFloat(MoonGravityOneShotTime), ResetGravity, data);
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：所有人限时 %d 秒月球重力", attackerName, GetConVarInt(MoonGravityOneShotTime));
		return Plugin_Continue;
	}

	currentChance += chanceMoonGravityOne;
	if (random <= currentChance)
	{
		// Limited time moon gravity for drawer
		SetEntityGravity(attacker, GetConVarFloat(MoonGravity));
		StringMap data = new StringMap();
		data.SetValue("client", attacker);
		data.SetValue("resetAll", false);
		CreateTimer(GetConVarFloat(MoonGravityOneShotTime), ResetGravity, data);
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：限时 %d 秒月球重力体验卡", attackerName, GetConVarInt(MoonGravityOneShotTime));
		return Plugin_Continue;
	}

	currentChance += chanceAverageHealth;
	if (random <= currentChance)
	{
		// Average all survivors' health
		int health = 0;
		for (int i = 0; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				health += GetClientHealth(i);
			}
		}
		int numOfAliveClient = 0;
		for (int i = 0; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				numOfAliveClient++;
			}
		}
		int averageHealth = RoundToNearest(float(health) / float(numOfAliveClient));
		for (int i = 0; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				SetEntityHealth(i, averageHealth);
			}
		}
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：所有人平均血量 %d", attackerName, averageHealth);
		return Plugin_Continue;
	}

	currentChance += chanceMoonGravityToggle;
	if (random <= currentChance)
	{
		// Toggle moon gravity for all survivors
		if (IsMoonGravity == 0)
		{
			IsMoonGravity = 1;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					SetEntityGravity(i, GetConVarFloat(MoonGravity));
				}
			}
			TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：所有幸存者获得月球重力", attackerName);
		}
		else {
			IsMoonGravity = 0;
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidAliveClient(i))
				{
					SetEntityGravity(i, 1.00);
				}
			}
			TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：取消月球重力", attackerName);
		}
		return Plugin_Continue;
	}

	currentChance += chanceIncreaseGravity;
	if (random <= currentChance)
	{
		// Increase gravity for drawer
		SetEntityGravity(attacker, GetConVarFloat(IncreasedGravity));
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：获得 %.1f 倍重力", attackerName, GetConVarFloat(IncreasedGravity));
		return Plugin_Continue;
	}

	currentChance += chanceDecreaseHealth;
	if (random <= currentChance)
	{
		// Decrease drawer's health randomly, the timer is to use avoid the conflict with other plugins
		// which will increase health after killing a tank.
		CreateTimer(2.0, DecreaseHealth, attacker);
		return Plugin_Continue;
	}

	// This shouldn't happen, but just in case
	TankDraw_PrintToChat(0, "抽奖出现意外，没有中奖");
	return Plugin_Continue;
}

Action DecreaseHealth(Handle timer, int attacker)
{
	char attackerName[MAX_NAME_LENGTH];
	GetClientName(attacker, attackerName, sizeof(attackerName));

	int minDecrease	 = GetConVarInt(MinHealthDecrease);
	int maxDecrease	 = GetConVarInt(MaxHealthDecrease);
	int randomHealth = GetRandomInt(minDecrease, maxDecrease);
	int health	 = GetClientHealth(attacker);
	if (health > randomHealth)
	{
		SetEntityHealth(attacker, health - randomHealth);
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：随机减少%d血量", attackerName, randomHealth);
	}
	else
	{
		SetEntityHealth(attacker, 1);
		TankDraw_PrintToChat(0, "玩家 %s 的幸运抽奖结果为：随机减少%d血量，但由于血量过低，所以仅剩1血量", attackerName, randomHealth);
	}

	return Plugin_Continue;
}

Action ResetGravity(Handle timer, Handle hndl)
{
	StringMap data = view_as<StringMap>(hndl);
	int	  client;
	bool	  resetAll;

	data.GetValue("client", client);
	data.GetValue("resetAll", resetAll);

	if (resetAll)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidAliveClient(i))
			{
				SetEntityGravity(i, 1.0);
			}
		}
		TankDraw_PrintToChat(0, "所有玩家重力恢复正常");
	}
	else
	{
		if (IsValidAliveClient(client))
		{
			SetEntityGravity(client, 1.0);
			TankDraw_PrintToChat(client, "你的重力恢复正常");
		}
	}

	delete data;
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

/**
 * Prints a formatted message with a [Tank Draw] prefix to chat.
 *
 * @param client    Client index to send the message to, or 0 for all players.
 * @param format    Formatting rules.
 * @param ...       Variable number of format parameters.
 */
stock void TankDraw_PrintToChat(int client = 0, const char[] format, any...)
{
	char buffer[254];
	VFormat(buffer, sizeof(buffer), format, 3);

	char message[254];
	Format(message, sizeof(message), "\x04[Tank Draw]\x03 %s", buffer);

	if (client == 0)
	{
		PrintToChatAll(message);
	}
	else if (IsClientInGame(client) && !IsFakeClient(client))
	{
		PrintToChat(client, message);
	}
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