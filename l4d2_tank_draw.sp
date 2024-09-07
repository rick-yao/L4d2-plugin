#pragma semicolon 1
#pragma newdecls required 1	   // force new syntax

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"
#define PLUGIN_FLAG    FCVAR_SPONLY | FCVAR_NOTIFY
#define COMMAND_FILTER COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_BOTS

#define Z_TANK 8

#define IsValidClient(%1)		(1 <= %1 <= MaxClients && IsClientInGame(%1))
#define IsValidAliveClient(%1)	(1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1))

public Plugin myinfo =
{
	author = "test plugin by rick",
}

public void
	OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}


public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Check if the victim is a Tank
	int  victim   = GetClientOfUserId(event.GetInt("userid"));
	if(!IsTank(victim)){
		PrintToServer("[Tank Draw] Victim is not a Tank. Exiting event.");
		return Plugin_Continue;
	}

	// if the victim is a tank, check if the weapon is a melee weapon
	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if(!StrEqual(weapon, "melee", false)){
		PrintToServer("[Tank Draw] Melee weapon detected. Exiting event.");
		return Plugin_Continue;
	}

	// check if the attacker is an alive client
	int  attacker = GetClientOfUserId(event.GetInt("attacker"));
	if(!IsValidAliveClient(attacker)){
		PrintToServer("[Tank Draw] Attacker is not a valid alive client. Exiting event.");
		return Plugin_Continue;
	}

	// now the attacker is a valid alive client and the weapon is a melee weapon
	// so we can make the tank draw
	PrintToServer("[Tank Draw] Event_PlayerDeath triggered. Victim: %d, Attacker: %d, weapon: %s", victim, attacker, weapon);

	char victimName[MAX_NAME_LENGTH], attackerName[MAX_NAME_LENGTH];
	GetClientName(victim, victimName, sizeof(victimName));
	GetClientName(attacker, attackerName, sizeof(attackerName));
	PrintToChatAll("[Tank Draw] %s 被玩家 %s 用近战武器击杀，开始幸运抽奖", victimName, attackerName);

	// TODO: 幸运抽奖逻辑
	LuckyDraw(victim, attacker);

	float tankPos[3];
	GetClientAbsOrigin(victim, tankPos);
	PrintToServer("[Tank Draw] Tank death position: %.2f, %.2f, %.2f", tankPos[0], tankPos[1], tankPos[2]);

	return Plugin_Continue;
}

bool IsTank(int client)
{
	return (GetEntProp(client, Prop_Send, "m_zombieClass") == Z_TANK);
}

void LuckyDraw(int victim, int attacker)
{
	PrintToChatAll("[Tank Draw] 幸运抽奖开始");
	
	int health = GetClientHealth(attacker) + 2000;
	SetEntityHealth(attacker, health);
	PrintToChatAll("[Tank Draw] 玩家 %N 的幸运抽奖结果为：%d", attacker, health);
}