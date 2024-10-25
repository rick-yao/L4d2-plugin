#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <multicolors>
#include <left4dhooks>

#define PLUGIN_VERSION "0.1"

#define Z_SMOKER       1
#define Z_BOOMER       2
#define Z_HUNTER       3
#define Z_SPITTER      4
#define Z_JOCKEY       5
#define Z_CHARGER      6

ConVar
	ChanceCarAlarm,
	ChanceWitchKilled;

public Plugin Info = {
	author	    = "Rick",
	name	    = "L4D2 Tank Trigger",
	description = "Spawn tank randomly when something happens",
	version	    = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	LoadTranslations("l4d2_tank_trigger.phrases");

	ChanceCarAlarm	  = CreateConVar("l4d2_tank_trigger_chance_car_alarm", "30", "车被触发响动时召唤tank概率 | probability of spawning tank when trigger car alarm", _, true, 0.0, true, 100.0);
	ChanceWitchKilled = CreateConVar("l4d2_tank_trigger_chance_witch_killed", "30", "witch被杀时召唤tank概率 | probability of spawning tank when a witch is killed", _, true, 0.0, true, 100.0);

	AutoExecConfig(true, "l4d2_tank_trigger");
	PrintToServer("[Tank Trigger] Plugin loaded");

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
			CPrintToChatAll("%t", "TankTrigger_WitchNotKilledByHuman");
			PrintHintTextToAll("%t", "TankTrigger_WitchNotKilledByHuman_NoColor");
			return Plugin_Continue;
		}
		float pos[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos);
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		int random = GetRandomInt(1, 100);
		int chance = ChanceWitchKilled.IntValue;
		PrintToServer("chance witch killed: %d", chance);
		if (chance > 0 && random <= chance)
		{
			CPrintToChatAll("%t", "TankTrigger_WitchKilledSpawnTank", attackerName);
			PrintHintTextToAll("%t", "TankTrigger_WitchKilledSpawnTank_NoColor", attackerName);
			SpawnTank(pos);
		}
		return Plugin_Continue;
	}

	if (StrEqual(name, "triggered_car_alarm"))
	{
		int attacker = GetClientOfUserId(event.GetInt("userid"));
		if (!IsValidClient(attacker))
		{
			CPrintToChatAll("%t", "TankTrigger_CarNotTriggeredByHuman");
			PrintHintTextToAll("%t", "TankTrigger_CarNotTriggeredByHuman_NoColor");
			return Plugin_Continue;
		}

		float pos[3];
		GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", pos);
		char attackerName[MAX_NAME_LENGTH];
		GetClientName(attacker, attackerName, sizeof(attackerName));

		int random = GetRandomInt(1, 100);
		int chance = ChanceCarAlarm.IntValue;
		if (chance > 0 && random <= chance)
		{
			CPrintToChatAll("%t", "TankTrigger_CarTriggeredSpawnTank", attackerName);
			PrintHintTextToAll("%t", "TankTrigger_CarTriggeredSpawnTank_NoColor", attackerName);
			SpawnTank(pos);
		}
		return Plugin_Continue;
	}

	return Plugin_Continue;
}

void SpawnTank(float pos[3])
{
	bool SpawnSuccess = TrySpawnTank(pos, 10);
	if (SpawnSuccess)
	{
		CPrintToChatAll("%t", "TankTrigger_TankSpawnSuccess");
	}
	else
	{
		CPrintToChatAll("%t", "TankTrigger_TankSpawnFailed");
	}
}

bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients) return false;
	if (!IsClientConnected(client)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}

bool TrySpawnTank(const float pos[3], int maxRetries = 3)
{
	int  attempts  = 1;
	bool IsSuccess = false;

	while (attempts <= maxRetries && !IsSuccess)
	{
		IsSuccess = L4D2_SpawnTank(pos, NULL_VECTOR) > 0;

		if (IsSuccess)
		{
			PrintToServer("[Tank Spawner] Successfully spawned Tank at position: %.1f, %.1f, %.1f", pos[0], pos[1], pos[2]);
			PrintToServer("[Tank Spawner] Successfully spawned Tank at %d attempts", attempts);
			return true;
		}

		attempts++;
	}

	PrintToServer("[Tank Spawner] Failed to spawn Tank after %d attempts", maxRetries);
	return false;
}