#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <left4dhooks>

#include "../../lib/helper.sp"

#define PLUGIN_VERSION "1.0"

int
	g_iChanceCarAlarm,
	g_iChanceWitchKilled;

ConVar
	ChanceCarAlarm,
	ChanceWitchKilled;

public Plugin Info = {
	author	    = "Rick",
	name	    = "L4D2 Tank Trigger",
	description = "Spawn tank randomly when something happens",
	url	    = "https://github.com/rick-yao/L4d2-plugin",
	version	    = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	LoadTranslations("l4d2_tank_trigger.phrases");

	ChanceCarAlarm	  = CreateConVar("l4d2_tank_trigger_chance_car_alarm", "30", "车被触发响动时召唤tank概率 \nprobability of spawning tank when trigger car alarm", _, true, 0.0, true, 100.0);
	ChanceWitchKilled = CreateConVar("l4d2_tank_trigger_chance_witch_killed", "30", "witch被杀时召唤tank概率 \nprobability of spawning tank when a witch is killed", _, true, 0.0, true, 100.0);

	HookConVarChange(ChanceCarAlarm, ConVarChanged);
	HookConVarChange(ChanceWitchKilled, ConVarChanged);

	AutoExecConfig(true, "l4d2_tank_trigger");

	SetConVar();

	HookEvent("witch_killed", Event_Spawn);
	HookEvent("triggered_car_alarm", Event_Spawn);
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "witch_killed"))
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		if (!IsValidClient(attacker))
		{
			// CPrintToChatAll("%t", "TankTrigger_WitchNotKilledByHuman");
			// PrintHintTextToAll("%t", "TankTrigger_WitchNotKilledByHuman_NoColor");
			return Plugin_Continue;
		}
		float pos[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos);
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		int random = GetRandomInt(1, 100);
		int chance = g_iChanceWitchKilled;
		if (chance > 0 && random <= chance)
		{
			CPrintToChatAll("%t", "TankTrigger_WitchKilledSpawnTank", attackerName);
			PrintHintTextToAll("%t", "TankTrigger_WitchKilledSpawnTank_NoColor", attackerName);
			TrySpawnTank(pos, OnSpawnComplete);
		}
		return Plugin_Continue;
	}

	if (StrEqual(name, "triggered_car_alarm"))
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		if (!IsValidClient(attacker))
		{
			// CPrintToChatAll("%t", "TankTrigger_CarNotTriggeredByHuman");
			// PrintHintTextToAll("%t", "TankTrigger_CarNotTriggeredByHuman_NoColor");
			return Plugin_Continue;
		}

		float pos[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos);
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		int random = GetRandomInt(1, 100);
		int chance = g_iChanceCarAlarm;
		if (chance > 0 && random <= chance)
		{
			CPrintToChatAll("%t", "TankTrigger_CarTriggeredSpawnTank", attackerName);
			PrintHintTextToAll("%t", "TankTrigger_CarTriggeredSpawnTank_NoColor", attackerName);
			TrySpawnTank(pos, OnSpawnComplete);
		}
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

void OnSpawnComplete(bool success, int attempts)
{
	if (success)
	{
		CPrintToChatAll("%t", "TankTrigger_TankSpawnSuccess");
	}
	else
	{
		CPrintToChatAll("%t", "TankTrigger_TankSpawnFailed");
	}
}
void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	SetConVar();
}

void SetConVar()
{
	g_iChanceCarAlarm    = ChanceCarAlarm.IntValue;
	g_iChanceWitchKilled = ChanceWitchKilled.IntValue;
}